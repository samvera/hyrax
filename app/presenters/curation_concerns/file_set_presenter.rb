module CurationConcerns
  class FileSetPresenter
    include ModelProxy
    include PresentsAttributes
    attr_accessor :solr_document, :current_ability, :request

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher,
             :language, :date_uploaded, :rights,
             :embargo_release_date, :lease_expiration_date,
             :depositor, :keyword, :title_or_label, to: :solr_document

    def page_title
      Array.wrap(solr_document['label_tesim']).first
    end

    def link_name
      current_ability.can?(:read, id) ? Array.wrap(solr_document['label_tesim']).first : 'File'
    end
  end
end
