module CurationConcerns
  class CollectionPresenter
    include ModelProxy
    include PresentsAttributes
    include ActionView::Helpers::NumberHelper
    attr_accessor :solr_document, :current_ability

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id,
             to: :solr_document

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :language,
             :embargo_release_date, :lease_expiration_date, :rights, to: :solr_document

    def size
      number_to_human_size(@solr_document['bytes_is'])
    end

    def total_items
      @solr_document['member_ids_ssim'].length
    end
  end
end
