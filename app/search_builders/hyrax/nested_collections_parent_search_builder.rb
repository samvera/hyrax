# frozen_string_literal: true
module Hyrax
  ##
  # Searches for all collections that are parents of a given collection.
  class NestedCollectionsParentSearchBuilder < ::Hyrax::CollectionSearchBuilder
    include Hyrax::FilterByType
    attr_reader :child, :page, :limit

    # @param [Object] scope Typically the controller object
    # @param [ActiveFedora::Base] child The child collection
    def initialize(scope:, child:, page:)
      @child = child
      @page = page
      super(scope)
    end

    ##
    # Filters the query to only include the parent collections
    #
    # @param [Hash] solr_parameters
    #
    # @return [void]
    def parent_collections_only(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] += [process_fq]
    end
    self.default_processor_chain += [:parent_collections_only]

    ##
    # @param [Hash] solr_parameters
    #
    # @return [void]
    def with_pagination(solr_parameters)
      solr_parameters[:page] = page
    end
    self.default_processor_chain += [:with_pagination]

    private

    def process_fq
      ids = child.member_of_collection_ids.reject(&:blank?)

      return "id:NEVER_USE_THIS_ID" if ids.empty?
      Hyrax::SolrQueryService.new.with_ids(ids: child.member_of_collection_ids).build
    end
  end
end
