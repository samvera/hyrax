module Hyrax
  module Collections
    module NestedCollectionQueryService
      # @api public
      #
      # What possible collections can nested within the given parent collection?
      #
      # @param parent [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return [Array<SolrDocument>]
      def self.available_child_collections(parent:, scope:)
        return [] unless parent.try(:nestable?)
        return [] unless scope.can?(:read, parent)
        query_solr(collection: parent, access: :edit, scope: scope)
      end

      # @api public
      #
      # What possible collections can the given child be nested within?
      #
      # @param child [Collection]
      # @param scope [Object] Typically a controller object that responds to `repository`, `can?`, `blacklight_config`, `current_ability`
      # @return [Array<SolrDocument>]
      def self.available_parent_collections(child:, scope:)
        return [] unless child.try(:nestable?)
        return [] unless scope.can?(:edit, child)
        query_solr(collection: child, access: :read, scope: scope)
      end

      # @api private
      def self.query_solr(collection:, access:, scope:)
        query_builder = Hyrax::Dashboard::NestedCollectionsSearchBuilder.new(access: access, collection: collection, scope: scope)
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
      # @return [Boolean] true if the parent can nest the child; false otherwise
      # @todo Consider expanding from same collection type to a lookup table that says "This collection type can have within it, these collection types"
      def self.parent_and_child_can_nest?(parent:, child:)
        return false unless parent.try(:nestable?)
        return false unless child.try(:nestable?)
        return false if parent == child
        parent.collection_type_gid == child.collection_type_gid
      end
    end
  end
end
