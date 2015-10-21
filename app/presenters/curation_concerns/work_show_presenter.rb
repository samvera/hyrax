module CurationConcerns
  class WorkShowPresenter
    include ModelProxy
    include PresentsAttributes
    attr_accessor :solr_document, :current_ability

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    def page_title
      solr_document.title
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id, :to_s,
             to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :language,
             :embargo_release_date, :lease_expiration_date, :rights, to: :solr_document

    def file_presenters
      @file_sets ||= begin
        # TODO: Extract this to ActiveFedora::Aggregations::ListSource
        ids = ActiveFedora::SolrService.query("proxy_in_ssi:#{id}", fl: "ordered_targets_ssim")
              .flat_map { |x| x.fetch("ordered_targets_ssim", []) }
        PresenterFactory.build_presenters(ids, FileSetPresenter, current_ability)
      end
    end
  end
end
