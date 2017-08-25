module Hyrax
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

    delegate(*Hyrax::CollectionType.collection_type_settings_methods, to: :collection_type, prefix: :collection_type_is)

    # @note This is an ugly hack. In working with Lynette, we discovered that the collection_type_gid
    #       was in the solr_document if the Collection was created via the UI. If the collection
    #       was created by factory girl then collection_type_gid was not in the solr_document.
    #       The long-term solution is to ensure that the SOLR document has some key for the collection_type.
    # @todo Change behavior when https://github.com/samvera/hyrax/pull/1556 is integrated
    def collection_type
      @collection_type ||= begin
        collection_type_gid =
          if solr_document.key?('collection_type_gid_ssim')
            # Taking a short cut if we know the collection type based on the SOLR document
            Array.wrap(solr_document.fetch('collection_type_gid_ssim')).first
          else
            solr_document.hydra_model.find(solr_document.id).collection_type_gid
          end
        if collection_type_gid
          Hyrax::CollectionType.find_by_gid!(collection_type_gid)
        else
          Hyrax::CollectionType.find_or_create_default_collection_type
        end
      end
    end

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :keyword, :language,
             :embargo_release_date, :lease_expiration_date, :license, :date_created,
             :resource_type, :based_near, :related_url, :identifier, :thumbnail_path,
             :title_or_label, :collection_type_gid_ssim, :create_date, :visibility, :edit_groups,
             :edit_people,
             to: :solr_document

    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [:total_items, :size, :resource_type, :creator, :contributor, :keyword,
       :license, :publisher, :date_created, :subject, :language, :identifier,
       :based_near, :related_url]
    end

    def terms_with_values
      self.class.terms.select { |t| self[t].present? }
    end

    def [](key)
      case key
      when :size
        size
      when :total_items
        total_items
      else
        solr_document.send key
      end
    end

    def size
      number_to_human_size(@solr_document['bytes_lts'])
    end

    def total_items
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}").count
    end

    def collection_type_badge
      collection_type.title
    end
  end
end
