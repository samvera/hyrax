module Hyrax
  # Responsible for adding the necessary callbacks for updating the nested collection information
  # This is part of the after update index because it is a potentially very expensive process.
  #
  # @todo Consider extracting the update_index callback to ActiveFedora::Base
  module CollectionNesting
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :update_index, only: :after
      after_update_index :update_nested_collection_relationship_indices
      after_destroy :update_child_nested_collection_relationship_indices

      def update_nested_collection_relationship_indices
        Hyrax.config.nested_relationship_reindexer.call(id: id)
      end

      def update_child_nested_collection_relationship_indices
        children = find_children_of(destroyed_id: id)
        children.each do |child|
          Hyrax.config.nested_relationship_reindexer.call(id: child.id)
        end
      end
    end

    def update_index(*args)
      _run_update_index_callbacks { super }
    end

    def find_children_of(destroyed_id:)
      ActiveFedora::SolrService.query(ActiveFedora::SolrQueryBuilder.construct_query(member_of_collection_ids_ssim: destroyed_id))
    end

    def use_nested_reindexing?
      true
    end
  end
end
