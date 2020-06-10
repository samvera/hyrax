# frozen_string_literal: true
module Hyrax
  # Searches for all collections that are parents of a given collection.
  class NestedCollectionsParentSearchBuilder < ::SearchBuilder
    include Hyrax::FilterByType
    attr_reader :child, :page, :limit

    # @param [scope] Typically the controller object
    # @param [child] The child collection
    def initialize(scope:, child:, page:)
      @child = child
      @page = page
      super(scope)
    end

    # Filters the query to only include the parent collections
    def parent_collections_only(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [Hyrax::SolrQueryBuilderService.construct_query_for_ids(child.member_of_collection_ids)]
    end
    self.default_processor_chain += [:parent_collections_only]

    def with_pagination(solr_parameters)
      solr_parameters[:page] = page
    end
    self.default_processor_chain += [:with_pagination]
  end
end
