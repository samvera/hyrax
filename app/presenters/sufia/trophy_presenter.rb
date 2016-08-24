module Sufia
  class TrophyPresenter
    include CurationConcerns::ModelProxy
    def initialize(solr_document)
      @solr_document = solr_document
    end

    attr_reader :solr_document

    delegate :to_s, to: :solr_document

    def self.find_by_user(user)
      work_ids = user.trophies.pluck(:work_id)
      query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids(work_ids)
      results = CurationConcerns::WorkRelation.new.search_with_conditions(query)
      results.map { |result| TrophyPresenter.new(document_model.new(result)) }
    rescue RSolr::Error::ConnectionRefused
      []
    end

    def thumbnail_path
      solr_document[CatalogController.blacklight_config.index.thumbnail_field]
    end

    def self.document_model
      CatalogController.blacklight_config.document_model
    end
    private_class_method :document_model
  end
end
