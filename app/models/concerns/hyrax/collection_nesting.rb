# frozen_string_literal: true
module Hyrax
  # Responsible for adding the necessary callbacks for updating the nested collection information
  # This is part of the after update index because it is a potentially very expensive process.
  #
  # @deprecation deprecated for removal in 4.0.0; nested reindexing is replaced by solr
  #   graph query. if you want to drop this behavior now, you can set
  #   +HYRAX_USE_SOLR_GRAPH_NESTING+ to +true+ in the environment.
  module CollectionNesting
    extend ActiveSupport::Concern

    included do
      Deprecation.warn "Hyrax::CollectionNesting is deprecated for removal in " \
                       "4.0.0. Nested reindexing behavior can be replaced " \
                       "by a Solr graph traversal query. Legacy nested " \
                       "indexing behavior is retained by default, but can be " \
                       "replaced with the 4.0.0 default by setting " \
                       "HYRAX_USE_SOLR_GRAPH_NESTING to `true` in the environment."

      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :update_index, only: :after
      after_update_index :update_nested_collection_relationship_indices
      after_destroy :update_child_nested_collection_relationship_indices
      before_save :before_update_nested_collection_relationship_indices
      after_save :after_update_nested_collection_relationship_indices

      def before_update_nested_collection_relationship_indices
        @during_save = true
      end

      def after_update_nested_collection_relationship_indices
        @during_save = false
        reindex_nested_relationships_for(id: id, extent: reindex_extent)
      end

      def update_nested_collection_relationship_indices
        return if @during_save
        reindex_nested_relationships_for(id: id, extent: reindex_extent)
      end

      def update_child_nested_collection_relationship_indices
        children = find_children_of(destroyed_id: id)
        children.each do |child|
          reindex_nested_relationships_for(id: child.id, extent: Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX)
        end
      end
    end

    def update_index(*args)
      _run_update_index_callbacks { super }
    end

    def find_children_of(destroyed_id:)
      Hyrax::SolrService.query(Hyrax::SolrQueryBuilderService.construct_query(member_of_collection_ids_ssim: destroyed_id))
    end

    # Only models which include Hyrax::CollectionNesting will respond to this method.
    # Used to determine whether a model gets reindexed via Samvera::NestingIndexer during full repository reindexing,
    def use_nested_reindexing?
      true
    end

    # The following methods allow an option to reindex an object only if the nesting indexer fields are not
    # already in the object's solr document. Added to prevent unnecessary indexing of all ancestors of a parent
    # when one child gets added to the parent. By default, we do the full graph indexing.
    def reindex_extent
      @reindex_extent ||= Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX
    end

    def reindex_extent=(val)
      @reindex_extent = val
    end

    private

    def reindex_nested_relationships_for(id:, extent:)
      Hyrax.config.nested_relationship_reindexer.call(id: id, extent: extent)
    end
  end
end
