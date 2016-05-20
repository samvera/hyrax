module CurationConcerns
  class CollectionPresenter
    include ModelProxy
    include PresentsAttributes
    include ActionView::Helpers::NumberHelper
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
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id,
             :to_s, to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :keyword, :language,
             :embargo_release_date, :lease_expiration_date, :rights, :date_created, to: :solr_document

    def size
      number_to_human_size(@solr_document['bytes_lts'])
    end

    def total_items
      @solr_document.fetch('member_ids_ssim', []).length
    end
  end
end
