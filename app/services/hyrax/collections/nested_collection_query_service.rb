module Hyrax
  module Collections
    module NestedCollectionQueryService
      # @api public
      #
      # What possible collections can nested within the given parent collection?
      #
      # @param parent [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @param limit_to_id [nil, String] Limit the query to just check if the given id is in the response. Useful for validation.
      # @return [Array<SolrDocument>]
      def self.available_child_collections(parent:, scope:, limit_to_id: nil)
        return [] unless parent.try(:nestable?)
        return [] unless scope.can?(:edit, parent)
        query_solr(collection: parent, access: :read, scope: scope, limit_to_id: limit_to_id)
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
        query_solr(collection: child, access: :edit, scope: scope, limit_to_id: limit_to_id)
      end

      # @api private
      #
      # @param collection [Collection]
      # @param access [Symbol]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @param limit_to_id [nil, String] Limit the query to just check if the given id is in the response. Useful for validation.
      def self.query_solr(collection:, access:, scope:, limit_to_id:)
        query_builder = Hyrax::Dashboard::NestedCollectionsSearchBuilder.new(access: access, collection: collection, scope: scope)
        # No sense returning everything, just limit to a single entry
        query_builder.where(id: limit_to_id) if limit_to_id
        scope.repository.search(query_builder.query).documents
      end
      private_class_method :query_solr

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
    end
  end
end
