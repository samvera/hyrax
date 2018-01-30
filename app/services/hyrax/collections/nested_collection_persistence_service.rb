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
      def self.persist_nested_collection_for(parent:, child:)
        child.member_of_collections << parent
        child.save
      end
    end
  end
end
