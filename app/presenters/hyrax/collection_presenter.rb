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

    def collection_type
      gid = Array.wrap(solr_document.fetch('collection_type_gid_ssim', [])).first
      @collection_type ||= CollectionType.find_by_gid!(gid, true)
    end

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :keyword, :language,
             :embargo_release_date, :lease_expiration_date, :license, :date_created,
             :resource_type, :based_near, :related_url, :identifier, :thumbnail_path,
             :title_or_label, :collection_type_gid_ssim, :create_date, :modified_date, :visibility, :edit_groups,
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

    def total_viewable_items
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}").accessible_by(current_ability).count
    end

    def total_viewable_works
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Work").accessible_by(current_ability).count
    end

    def total_viewable_collections
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Collection").accessible_by(current_ability).count
    end

    def collection_type_badge
      collection_type.title
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.dashboard_collection_path(id)
    end

    def banner_file
      # Find Banner filename
      ci = CollectionBrandingInfo.where(collection_id: id, role: "banner")
      "/" + ci[0].local_path.split("/")[-4..-1].join("/") unless ci.empty?
    end

    def logo_record
      logo_info = []
      # Find Logo filename, alttext, linktext
      cis = CollectionBrandingInfo.where(collection_id: id, role: "logo")
      return if cis.empty?
      cis.each do |coll_info|
        logo_file = File.split(coll_info.local_path).last
        file_location = "/" + coll_info.local_path.split("/")[-4..-1].join("/") unless logo_file.empty?
        alttext = coll_info.alt_text
        linkurl = coll_info.target_url
        logo_info << { file: logo_file, file_location: file_location, alttext: alttext, linkurl: linkurl }
      end
      logo_info
    end
  end
end
