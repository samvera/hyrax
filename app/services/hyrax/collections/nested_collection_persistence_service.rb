module Hyrax
  module Collections
    module NestedCollectionPersistenceService
      # @api public
      #
      # Responsible for persisting the relationship between the parent and the child.
      #
      # @param parent [Collection]
      # @param child [Collection]
      # @note There appears to be a logical disconnect between the PCDM implementation of
      #   Collections and the validation of nesting collections:
      #   * For PCDM the "parent has_member child" relationship is defined, and managed on the parent.
      #   * For the Nesting collections, we require that:
      #     * The child is EDIT-able by the user
      #     * The parent is READ-able by the user
      #   The Nesting collections requirement implies that the PCDM relationship is pointing in the wrong direction.
      def self.persist_nested_collection_for(parent:, child:)
        parent.members << child
        parent.save
      end
    end
  end
end
