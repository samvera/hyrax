# frozen_string_literal: true
module Hyrax
  class CollectionPresenter
    include ModelProxy
    include PresentsAttributes
    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::TagHelper
    attr_accessor :solr_document, :current_ability, :request
    attr_reader :subcollection_count
    attr_accessor :parent_collections # This is expected to be a Blacklight::Solr::Response with all of the parent collections
    attr_writer :collection_type

    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = Hyrax::SelectTypeListPresenter

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
      @subcollection_count = 0
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id,
             :to_s, to: :solr_document

    delegate(*Hyrax::CollectionType.settings_attributes, to: :collection_type, prefix: :collection_type_is)
    alias nestable? collection_type_is_nestable?

    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    # Metadata Methods
    delegate :title, :description, :creator, :contributor, :subject, :publisher, :keyword, :language, :embargo_release_date,
             :lease_expiration_date, :license, :date_created, :resource_type, :based_near, :related_url, :identifier, :thumbnail_path,
             :title_or_label, :collection_type_gid, :create_date, :modified_date, :visibility, :edit_groups, :edit_people,
             to: :solr_document

    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [:total_items, :size, :resource_type, :creator, :contributor, :keyword, :license, :publisher, :date_created, :subject,
       :language, :identifier, :based_near, :related_url]
    end

    def terms_with_values
      self.class.terms.select { |t| self[t].present? }
    end

    ##
    # @param [Symbol] key
    # @return [Object]
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

    # @deprecated to be removed in 4.0.0; this feature was replaced with a
    #   hard-coded null implementation
    # @return [String] 'unknown'
    def size
      Deprecation.warn('#size has been deprecated for removal in Hyrax 4.0.0; ' \
                       'The implementation of the indexed Collection size ' \
                       'feature is extremely inefficient, so it has been removed. ' \
                       'This method now returns a hard-coded `"unknown"` for ' \
                       'compatibility.')
      'unknown'
    end

    def total_items
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .count
    end

    def total_viewable_items
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .accessible_by(ability: current_ability)
                      .count
    end

    def total_viewable_works
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .with_generic_type(generic_type: "Work")
                      .accessible_by(ability: current_ability)
                      .count
    end

    def total_viewable_collections
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .with_generic_type(generic_type: "Collection")
                      .accessible_by(ability: current_ability)
                      .count
    end

    def collection_type_badge
      tag.span(collection_type.title, class: "badge", style: "background-color: " + collection_type.badge_color + ";")
    end

    # The total number of parents that this collection belongs to, visible or not.
    def total_parent_collections
      parent_collections.blank? ? 0 : parent_collections.response['numFound']
    end

    # The number of parent collections shown on the current page. This will differ from total_parent_collections
    # due to pagination.
    def parent_collection_count
      parent_collections.blank? ? 0 : parent_collections.documents.size
    end

    def user_can_nest_collection?
      current_ability.can?(:deposit, solr_document)
    end

    def user_can_create_new_nest_collection?
      current_ability.can?(:create_collection_of_type, collection_type)
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.dashboard_collection_path(id, locale: I18n.locale)
    end

    ##
    # @return [#to_s, nil] a download path for the banner file
    def banner_file
      banner = CollectionBrandingInfo.find_by(collection_id: id, role: "banner")
      "/" + banner.local_path.split("/")[-4..-1].join("/") if banner
    end

    def logo_record
      CollectionBrandingInfo.where(collection_id: id, role: "logo")
                            .select(:local_path, :alt_text, :target_url).map do |logo|
        { alttext: logo.alt_text,
          file: File.split(logo.local_path).last,
          file_location: "/#{logo.local_path.split('/')[-4..-1].join('/')}",
          linkurl: logo.target_url }
      end
    end

    # A presenter for selecting a work type to create
    # this is needed here because the selector is in the header on every page
    def create_work_presenter
      @create_work_presenter ||= create_work_presenter_class.new(current_ability.current_user)
    end

    def create_many_work_types?
      create_work_presenter.many?
    end

    def draw_select_work_modal?
      create_many_work_types?
    end

    def first_work_type
      create_work_presenter.first_model
    end

    ##
    # @deprecated this implementation requires an extra db round trip, had a
    #   buggy cacheing mechanism, and was largely duplicative of other code.
    #   all versions of this code are replaced by
    #   {CollectionsHelper#available_parent_collections_data}.
    def available_parent_collections(scope:)
      Deprecation.warn("#{self.class}#available_parent_collections is " \
                       "deprecated. Use available_parent_collections_data " \
                       "helper instead.")
      return @available_parents if @available_parents.present?
      collection = Hyrax.config.collection_class.find(id)
      colls = Hyrax::Collections::NestedCollectionQueryService.available_parent_collections(child: collection, scope: scope, limit_to_id: nil)
      @available_parents = colls.map do |col|
        { "id" => col.id, "title_first" => col.title.first }
      end.to_json
    end

    def subcollection_count=(total)
      @subcollection_count = total unless total.nil?
    end

    # For the Managed Collections tab, determine the label to use for the level of access the user has for this admin set.
    # Checks from most permissive to most restrictive.
    # @return String the access label (e.g. Manage, Deposit, View)
    def managed_access
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.manage') if current_ability.can?(:edit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.deposit') if current_ability.can?(:deposit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.view') if current_ability.can?(:read, solr_document)
      ''
    end

    # Determine if the user can perform batch operations on this collection.  Currently, the only
    # batch operation allowed is deleting, so this is equivalent to checking if the user can delete
    # the collection determined by criteria...
    # * user must be able to edit the collection to be able to delete it
    # * the collection does not have to be empty
    # @return Boolean true if the user can perform batch actions; otherwise, false
    def allow_batch?
      return true if current_ability.can?(:edit, solr_document)
      false
    end
  end
end
