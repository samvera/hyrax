module Hyrax
  module Collections
    module NestedCollectionPersistenceService
      # @api public
      #
      # Responsible for persisting the relationship between the parent and the child.
      #
      # @param parent [Collection]
      # @param child [Collection]
      def self.persist_nested_collection_for(parent:, child:)
        raise NotImplementedError
      end
    end
  end
end
