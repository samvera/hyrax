module Hyrax
  module Collections
    module NestedCollectionQueryService
      # @api private
      #
      # an encapsulation of a collection's nesting index attributes
      #
      # @param id [String] a collection id
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return object [NestingAttributes]
      class NestingAttributes
        attr_accessor :parents, :pathnames, :ancestors, :depth, :id

        def initialize(id:, scope:)
          query_builder = Hyrax::CollectionSearchBuilder.new(scope).where(id: id)
          query = Hyrax::Collections::NestedCollectionQueryService.clean_lucene_error(builder: query_builder)
          response = scope.repository.search(query)
          collection_doc = response.documents.first
          @id = id
          @parents = collection_doc[Samvera::NestingIndexer.configuration.solr_field_name_for_storing_parent_ids]
          @pathnames = collection_doc[Samvera::NestingIndexer.configuration.solr_field_name_for_storing_pathnames]
          @ancestors = collection_doc[Samvera::NestingIndexer.configuration.solr_field_name_for_storing_ancestors]
          @depth = collection_doc[Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth]
        end
      end

      # @api public
      #
      # What possible collections can be nested within the given parent collection?
      #
      # @param parent [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @param limit_to_id [nil, String] Limit the query to just check if the given id is in the response. Useful for validation.
      # @return [Array<SolrDocument>]
      def self.available_child_collections(parent:, scope:, limit_to_id: nil)
        return [] unless parent.try(:nestable?)
        return [] unless scope.can?(:deposit, parent)
        query_solr(collection: parent, access: :read, scope: scope, limit_to_id: limit_to_id, nest_direction: :as_child).documents
      end

      # @api public
      #
      # What possible collections can the given child be nested within?
      #
      # @param child [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @param limit_to_id [nil, String] Limit the query to just check if the given id is in the response. Useful for validation.
      # @return [Array<SolrDocument>]
      def self.available_parent_collections(child:, scope:, limit_to_id: nil)
        return [] unless child.try(:nestable?)
        return [] unless scope.can?(:read, child)
        query_solr(collection: child, access: :deposit, scope: scope, limit_to_id: limit_to_id, nest_direction: :as_parent).documents
      end

      # @api public
      #
      # What collections is the given child nested within?
      #
      # @param child [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @param page [Integer] Starting page for pagination
      # @param limit [Integer] Limit to number of collections for pagination
      # @return [Blacklight::Solr::Response]
      def self.parent_collections(child:, scope:, page: 1)
        return [] unless child.try(:nestable?)
        query_builder = Hyrax::NestedCollectionsParentSearchBuilder.new(scope: scope, child: child, page: page)
        query = clean_lucene_error(builder: query_builder)
        scope.repository.search(query)
      end

      # @api private
      #
      # @param collection [Collection]
      # @param access [Symbol] I need this kind of permission on the queried objects.
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @param limit_to_id [nil, String] Limit the query to just check if the given id is in the response. Useful for validation.
      # @param nest_direction [Symbol] :as_child or :as_parent
      def self.query_solr(collection:, access:, scope:, limit_to_id:, nest_direction:)
        nesting_attributes = NestingAttributes.new(id: collection.id, scope: scope)
        query_builder = Hyrax::Dashboard::NestedCollectionsSearchBuilder.new(
          access: access,
          collection: collection,
          scope: scope,
          nesting_attributes: nesting_attributes,
          nest_direction: nest_direction
        )

        query_builder.where(id: limit_to_id) if limit_to_id
        query = clean_lucene_error(builder: query_builder)
        scope.repository.search(query)
      end
      private_class_method :query_solr

      # @api private
      #
      # clean query for {!lucene} error
      #
      # @param builder [SearchBuilder]
      # @return [Blacklight::Solr::Request] cleaned and functional query
      def self.clean_lucene_error(builder:)
        # TODO: Need to investigate further to understand why these particular queries using the where cause fail when others in the app apparently work
        query = builder.query.to_hash
        query['q'].gsub!('{!lucene}', '') if query.key? 'q'
        query
      end

      # @api public
      #
      # @note There is a short-circuit of logic; To be robust, we should ensure that the child and parent are in the corresponding available collections
      #
      # Is it valid to nest the given child within the given parent?
      #
      # @param parent [Collection]
      # @param child [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return [Boolean] true if the parent can nest the child; false otherwise
      # @todo Consider expanding from same collection type to a lookup table that says "This collection type can have within it, these collection types"
      def self.parent_and_child_can_nest?(parent:, child:, scope:)
        return false if parent == child # Short-circuit
        return false unless parent.collection_type_gid == child.collection_type_gid
        return false if available_parent_collections(child: child, scope: scope, limit_to_id: parent.id).none?
        return false if available_child_collections(parent: parent, scope: scope, limit_to_id: child.id).none?
        true
      end

      # @api public
      #
      # Does the nesting depth fall within defined limit?
      #
      # @param parent [Collection]
      # @param child [nil, Collection] will be nil if we are nesting a new collection under the parent
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return [Boolean] true if the parent can nest the child; false otherwise
      def self.valid_combined_nesting_depth?(parent:, child: nil, scope:)
        # We limit the total depth of collections to the size specified in the samvera-nesting_indexer configuration.
        child_depth = child_nesting_depth(child: child, scope: scope)
        parent_depth = parent_nesting_depth(parent: parent, scope: scope)
        return false if parent_depth + child_depth > Samvera::NestingIndexer.configuration.maximum_nesting_depth
        true
      end

      # @api private
      #
      # Get the child collection's nesting depth
      #
      # @param child [Collection]
      # @return [Fixnum] the largest number of collections in a path nested under this collection (including this collection)
      def self.child_nesting_depth(child:, scope:)
        return 1 if child.nil?
        # The nesting depth of a child collection is found by finding the largest nesting depth
        # among all collections and works which have the child collection in the paths, and
        # subtracting the nesting depth of the child collection itself.
        # => 1) First we find all the collections with this child in the path, sort the results in descending order, and take the first result.
        # note: We need to include works in this search. They are included in the depth validations in
        # the indexer, so we do NOT use collection search builder here.
        builder = Hyrax::SearchBuilder.new(scope).where("#{Samvera::NestingIndexer.configuration.solr_field_name_for_storing_pathnames}:/.*#{child.id}.*/")
        builder.query[:sort] = "#{Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth} desc"
        builder.query[:rows] = 1
        query = clean_lucene_error(builder: builder)
        response = scope.repository.search(query).documents.first

        # Now we have the largest nesting depth for all paths containing this collection
        descendant_depth = response[Samvera::NestingIndexer.configuration.solr_field_name_for_deepest_nested_depth]

        # => 2) Then we get the stored depth of the child collection itself to eliminate the collections above this one from our count, and add 1 to add back in this collection itself
        child_depth = NestingAttributes.new(id: child.id, scope: scope).depth
        nesting_depth = descendant_depth - child_depth + 1

        return nesting_depth if nesting_depth > 0 # this should always be > 0, but just being safe
        1
      end
      private_class_method :child_nesting_depth

      # @api private
      #
      # Get the parent collection's nesting depth
      #
      # @param parent [Collection]
      # @return [Fixnum] the largest number of collections above this collection (includes this collection)
      def self.parent_nesting_depth(parent:, scope:)
        return 1 if parent.nil?
        NestingAttributes.new(id: parent.id, scope: scope).depth
      end
      private_class_method :parent_nesting_depth
    end
  end
end
