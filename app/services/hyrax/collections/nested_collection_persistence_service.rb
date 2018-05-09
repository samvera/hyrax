module Hyrax
  module Collections
    module NestedCollectionPersistenceService
      # @api public
      #
      # Responsible for persisting the relationship between the parent and the child.
      # @see Hyrax::Collections::NestedCollectionQueryService
      #
      # @param parent [Collection]
      # @param child [Collection]
      # @note There is odd permission arrangement based on the NestedCollectionQueryService:
      #       You can nest the child within a parent if you can edit the parent and read the child.
      #       See https://wiki.duraspace.org/display/samvera/Samvera+Tech+Call+2017-08-23 for tech discussion.
      # @note Adding the member_of_collections method doesn't trigger reindexing of the child so we have to do it manually.
      #       However it save and reindexes the parent unnecessarily!!
      def self.persist_nested_collection_for(parent:, child:)
        parent.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
        child.member_of_collections.push(parent)
        child.update_nested_collection_relationship_indices
      end

      # @note Removing the member_of_collections method doesn't trigger reindexing of the child so we have to do it manually.
      #       However it doesn't save and reindex the parent, as it does when a parent is added!!
      def self.remove_nested_relationship_for(parent:, child:)
        child.member_of_collections.delete(parent)
        child.update_nested_collection_relationship_indices
        true
      end
    end
  end
end
