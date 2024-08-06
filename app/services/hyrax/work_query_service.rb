# frozen_string_literal: true
module Hyrax
  # Responsible for retrieving information based on the given work.
  #
  # @see ProxyDepositRequest
  # @see Hyrax::VaklyrieWorkRelation
  # @see SolrDocument
  # @see Hyrax::SolrService
  # @see ActiveFedora::SolrQueryBuilder
  # @note This was extracted from the ProxyDepositRequest, which was coordinating lots of effort. It was also an ActiveRecord object that required lots of Fedora/Solr interactions.
  class WorkQueryService
    # @param [String] id - The id of the work
    # @param [#exists?, #find] work_relation - How we will query some of the related information
    def initialize(id:, work_relation: default_work_relation)
      @id = id
      @work_relation = work_relation
    end
    attr_reader :id, :work_relation

    private

    def default_work_relation
      Hyrax.config.disable_wings ? Hyrax::ValkyrieWorkRelation.new : Hyrax::WorkRelation.new
    end

    public

    # @return [Boolean] if the work has been deleted
    def deleted_work?
      !work_relation.exists?(id)
    end

    def work
      @work ||= work_relation.find(id)
    end

    def to_s
      if deleted_work?
        'work not found'
      else
        solr_doc.to_s
      end
    end

    private

    def solr_doc
      @solr_doc ||= ::SolrDocument.new(solr_response['response']['docs'].first, solr_response)
    end

    def solr_response
      @solr_response ||= Hyrax::SolrService.get(query)
    end

    def query
      Hyrax::SolrQueryService.new.with_ids(ids: [id]).build
    end
  end
end
