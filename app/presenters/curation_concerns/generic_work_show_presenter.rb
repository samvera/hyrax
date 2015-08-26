module CurationConcerns
  class GenericWorkShowPresenter
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
    delegate :stringify_keys, :human_readable_type, :collection?, :representative, :to_s,
             to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :language,
             :embargo_release_date, :lease_expiration_date, :rights, to: :solr_document

    def file_presenters
      @generic_files ||= begin
        ids = solr_document.fetch('generic_file_ids_ssim', [])
        load_generic_file_presenters(ids)
      end
    end

    private

      # @param [Array] ids the list of ids to load
      # @return [Array<GenericFilePresenter>] presenters for the generic files in order of the ids
      def load_generic_file_presenters(ids)
        return [] if ids.blank?
        docs = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}").map { |res| SolrDocument.new(res) }
        ids.map { |id| GenericFilePresenter.new(docs.find { |doc| doc.id == id }, current_ability) }
      end
  end
end
