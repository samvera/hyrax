# frozen_string_literal: true
module Hyrax
  module Dashboard
    # Responsible for searching for collections of the same type that are not the given collection
    class NestedCollectionsSearchBuilder < ::Hyrax::CollectionSearchBuilder
      # @param access [Symbol] :edit, :read, :discover - With the given :access what all can
      # @param collection [::Collection]
      # @param scope [Object] Typically a controller that responds to #current_ability, #blackligh_config
      # @param nest_direction [Symbol] (:as_parent or :as_child) the direction we are adding nesting to this collection
      def initialize(access:, collection:, scope:, nest_direction:)
        super(scope)
        @collection = collection
        @discovery_permissions = extract_discovery_permissions(access)
        @nest_direction = nest_direction
      end

      # Override for Hydra::AccessControlsEnforcement
      attr_reader :discovery_permissions
      self.default_processor_chain += [:with_pagination, :show_only_other_collections_of_the_same_collection_type]

      def with_pagination(solr_parameters)
        solr_parameters[:rows] = 1000
      end

      # Solr can do graph traversal without the need of special indexing with the Graph query parser so
      # use this to compute both the parents and children of the current collection then exclude them
      # See https://solr.apache.org/guide/solr/latest/query-guide/other-parsers.html#graph-query-parser
      def show_only_other_collections_of_the_same_collection_type(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
          Hyrax::SolrQueryBuilderService.construct_query(Hyrax.config.collection_type_index_field => @collection.collection_type_gid),
          "-{!graph from=id to=member_of_collection_ids_ssim#{' maxDepth=1' if @nest_direction == :as_parent}}id:#{@collection.id}",
          "-{!graph to=id from=member_of_collection_ids_ssim#{' maxDepth=1' if @nest_direction == :as_child}}id:#{@collection.id}"
        ]
      end
    end
  end
end
