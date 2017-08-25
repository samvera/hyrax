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
      #       However, in the future, instead of adding that relationship to the parent, we will be
      #       adding the relationship to the child. In a RDBMS environment, this would be resolved by
      #       creating a join table. One that we can check who added the relationship. However, we aren't
      #       using an RDBM.
      #       See https://wiki.duraspace.org/display/samvera/Samvera+Tech+Call+2017-08-23 for tech discussion.
      def self.persist_nested_collection_for(parent:, child:)
        parent.members << child
        parent.save
      end
    end
  end
end
