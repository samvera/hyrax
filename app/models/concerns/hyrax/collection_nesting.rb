module Hyrax
  module CollectionNesting
    extend ActiveSupport::Concern

    included do
      define_model_callbacks :update_index, only: :after
      after_update_index :update_nested_collection_relationship_indices
      def update_nested_collection_relationship_indices
        Hyrax.config.nested_relationship_reindexer.call(id: id)
      end
    end

    def update_index(*args)
      _run_update_index_callbacks { super }
    end
  end
end
