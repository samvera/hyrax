module CurationConcerns
  class GenericFilePresenter
    include ModelProxy
    include PresentsAttributes
    attr_accessor :solr_document, :current_ability

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher,
             :language, :date_uploaded, :rights,
             :embargo_release_date, :lease_expiration_date, to: :solr_document

    def page_title
      Array(solr_document['label_tesim']).first
    end

    def link_name
      current_ability.can?(:read, id) ? Array(solr_document['label_tesim']).first : 'File'
    end
  end
end
