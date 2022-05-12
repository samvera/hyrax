# frozen_string_literal: true
module Hyrax
  class WorkShowPresenter
    include ModelProxy
    include PresentsAttributes

    ##
    # @!attribute [w] member_presenter_factory
    #   @return [MemberPresenterFactory]
    attr_writer :member_presenter_factory
    attr_accessor :solr_document, :current_ability, :request

    class_attribute :collection_presenter_class, :presenter_factory_class

    # modify this attribute to use an alternate presenter class for the collections
    self.collection_presenter_class = CollectionPresenter
    self.presenter_factory_class = MemberPresenterFactory

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, :export_formats, :export_as, to: :solr_document

    # delegate fields from Hyrax::Works::Metadata to solr_document
    delegate :based_near_label, :related_url, :depositor, :identifier, :resource_type,
             :keyword, :itemtype, :admin_set, :rights_notes, :access_right, :abstract, to: :solr_document

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context. Used so
    #                                  the GraphExporter knows what URLs to draw.
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = Hyrax::SolrDocument::OrderedMembers.decorate(solr_document)
      @current_ability = current_ability
      @request = request
    end

    def page_title
      "#{human_readable_type} | #{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :to_s, :suppressed?,
             to: :solr_document

    # Metadata Methods
    delegate :title, :date_created, :description,
             :creator, :contributor, :subject, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :license, :source, :rights_statement, :thumbnail_id, :representative_id,
             :rendering_ids, :member_of_collection_ids, :alternative_title, to: :solr_document

    def workflow
      @workflow ||= WorkflowPresenter.new(solr_document, current_ability)
    end

    def inspect_work
      @inspect_workflow ||= InspectWorkPresenter.new(solr_document, current_ability)
    end

    # @return [String] a download URL, if work has representative media, or a blank string
    def download_url
      return '' if representative_presenter.nil?
      Hyrax::Engine.routes.url_helpers.download_url(representative_presenter, host: request.host)
    end

    # @return [Boolean] render a IIIF viewer
    def iiif_viewer?
      representative_id.present? &&
        representative_presenter.present? &&
        representative_presenter.image? &&
        Hyrax.config.iiif_image_server? &&
        members_include_viewable_image?
    end

    alias universal_viewer? iiif_viewer?
    deprecation_deprecate universal_viewer?: "use iiif_viewer? instead"

    # @return [Symbol] the name of the IIIF viewer partial to render
    # @example A work presenter with a custom iiif viewer
    #   module Hyrax
    #     class GenericWorkPresenter < Hyrax::WorkShowPresenter
    #       def iiif_viewer
    #         :my_iiif_viewer
    #       end
    #     end
    #   end
    #
    #   Custom iiif viewer partial at app/views/hyrax/base/iiif_viewers/_my_iiif_viewer.html.erb
    #   <h3>My IIIF Viewer!</h3>
    #   <a href=<%= main_app.polymorphic_url([main_app, :manifest, presenter], { locale: nil }) %>>Manifest</a>
    def iiif_viewer
      :universal_viewer
    end

    # @return FileSetPresenter presenter for the representative FileSets
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||=
        begin
          result = member_presenters([representative_id]).first
          return nil if result.try(:id) == id
          result.try(:representative_presenter) || result
        end
    end

    # Get presenters for the collections this work is a member of via the member_of_collections association.
    # @return [Array<CollectionPresenter>] presenters
    def member_of_collection_presenters
      PresenterFactory.build_for(ids: member_of_authorized_parent_collections,
                                 presenter_class: collection_presenter_class,
                                 presenter_args: presenter_factory_arguments)
    end

    def date_modified
      solr_document.date_modified.try(:to_formatted_s, :standard)
    end

    def date_uploaded
      solr_document.date_uploaded.try(:to_formatted_s, :standard)
    end

    def link_name
      current_ability.can?(:read, id) ? to_s : 'Private'
    end

    def export_as_nt
      graph.dump(:ntriples)
    end

    def export_as_jsonld
      graph.dump(:jsonld, standard_prefixes: true)
    end

    def export_as_ttl
      graph.dump(:ttl)
    end

    ##
    # @deprecated use `::Ability.can?(:edit, presenter)`. Hyrax views calling
    #   presenter {#editor} methods will continue to call them until Hyrax
    #   4.0.0. The deprecation time horizon for the presenter methods themselves
    #   is 5.0.0.
    def editor?
      current_ability.can?(:edit, self)
    end

    def tweeter
      TwitterPresenter.twitter_handle_for(user_key: depositor)
    end

    def presenter_types
      Hyrax.config.registered_curation_concern_types.map(&:underscore) + ["collection"]
    end

    # @return [Array] presenters grouped by model name, used to show the parents of this object
    def grouped_presenters(filtered_by: nil, except: nil)
      # TODO: we probably need to retain collection_presenters (as parent_presenters)
      #       and join this with member_of_collection_presenters
      grouped = member_of_collection_presenters.group_by(&:model_name).transform_keys(&:human)
      grouped.select! { |obj| obj.downcase == filtered_by } unless filtered_by.nil?
      grouped.except!(*except) unless except.nil?
      grouped
    end

    def work_featurable?
      user_can_feature_works? && solr_document.public?
    end

    def display_feature_link?
      work_featurable? && FeaturedWork.can_create_another? && !featured?
    end

    def display_unfeature_link?
      work_featurable? && featured?
    end

    def stats_path
      Hyrax::Engine.routes.url_helpers.stats_work_path(self, locale: I18n.locale)
    end

    def model
      solr_document.to_model
    end

    delegate :member_presenters, :ordered_ids, :file_set_presenters, :work_presenters, to: :member_presenter_factory

    # @return [Array] list to display with Kaminari pagination
    def list_of_item_ids_to_display
      paginated_item_list(page_array: authorized_item_ids)
    end

    ##
    # @deprecated use `#member_presenters(ids)` instead
    #
    # @param [Array<String>] ids a list of ids to build presenters for
    # @return [Array<presenter_class>] presenters for the array of ids (not filtered by class)
    def member_presenters_for(an_array_of_ids)
      Deprecation.warn("Use `#member_presenters` instead.")
      member_presenters(an_array_of_ids)
    end

    # @return [Integer] total number of pages of viewable items
    def total_pages
      (total_items.to_f / rows_from_params.to_f).ceil
    end

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    # IIIF rendering linking property for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add a 'rendering' (eg. a link a download for the resource)
    #
    # @return [Array] array of rendering hashes
    def sequence_rendering
      solr_document.rendering_ids.each_with_object([]) do |file_set_id, renderings|
        renderings << manifest_helper.build_rendering(file_set_id)
      end.flatten
    end

    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @return [Array] array of metadata hashes
    def manifest_metadata
      Hyrax.config.iiif_metadata_fields.each_with_object([]) do |field, metadata|
        metadata << {
          'label' => I18n.t("simple_form.labels.defaults.#{field}"),
          'value' => Array.wrap(send(field).map { |f| Loofah.fragment(f.to_s).scrub!(:whitewash).to_s })
        }
      end
    end

    ##
    # @return [Integer]
    def member_count
      @member_count ||= member_presenters.count
    end

    ##
    # Given a set of collections, which the caller asserts the current ability
    # can deposit to, decide whether to display actions to add this work to a
    # collection.
    #
    # By default, this returns `true` if any collections are passed in OR the
    # current ability can create a collection.
    #
    # @param collections [Enumerable<::Collection>, nil] list of collections to
    #   which the current ability can deposit
    #
    # @return [Boolean] a flag indicating whether to display collection deposit
    #   options.
    def show_deposit_for?(collections:)
      collections.present? ||
        current_ability.can?(:create_any, Hyrax.config.collection_class)
    end

    ##
    # @return [Array<Class>]
    def valid_child_concerns
      Hyrax::ChildTypes.for(parent: solr_document.hydra_model).to_a
    end

    private

    # list of item ids to display is based on ordered_ids
    def authorized_item_ids(filter_unreadable: Flipflop.hide_private_items?)
      @member_item_list_ids ||=
        filter_unreadable ? ordered_ids.reject { |id| !current_ability.can?(:read, id) } : ordered_ids
    end

    # Uses kaminari to paginate an array to avoid need for solr documents for items here
    def paginated_item_list(page_array:)
      Kaminari.paginate_array(page_array, total_count: page_array.size).page(current_page).per(rows_from_params)
    end

    def total_items
      authorized_item_ids.size
    end

    def rows_from_params
      request.params[:rows].nil? ? Hyrax.config.show_work_item_rows : request.params[:rows].to_i
    end

    def current_page
      page = request.params[:page].nil? ? 1 : request.params[:page].to_i
      page > total_pages ? total_pages : page
    end

    def manifest_helper
      @manifest_helper ||= ManifestHelper.new(request.base_url)
    end

    def featured?
      # only look this up if it's not boolean; ||= won't work here
      @featured = FeaturedWork.where(work_id: solr_document.id).exists? if @featured.nil?
      @featured
    end

    def user_can_feature_works?
      current_ability.can?(:create, FeaturedWork)
    end

    def presenter_factory_arguments
      [current_ability, request]
    end

    def member_presenter_factory
      @member_presenter_factory ||=
        if solr_document.hydra_model < Valkyrie::Resource
          PcdmMemberPresenterFactory.new(solr_document, current_ability)
        else
          self.class
              .presenter_factory_class
              .new(solr_document, current_ability, request)
        end
    end

    def graph
      GraphExporter.new(solr_document, hostname: request.host).fetch
    end

    # @return [Array<String>] member_of_collection_ids with current_ability access
    def member_of_authorized_parent_collections
      @member_of ||= Hyrax::CollectionMemberService.run(solr_document, current_ability).map(&:id)
    end

    def members_include_viewable_image?
      file_set_presenters.any? { |presenter| presenter.image? && current_ability.can?(:read, presenter.id) }
    end
  end
end
