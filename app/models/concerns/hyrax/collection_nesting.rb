module Hyrax
  module CollectionNesting
    extend ActiveSupport::Concern

    included do
      after_save :update_nested_collection_relationship_indices
      def update_nested_collection_relationship_indices
        Hyrax.config.nested_relationship_reindexer.call(id: id)
      end
    end
  end
end
