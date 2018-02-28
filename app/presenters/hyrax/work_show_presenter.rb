module Hyrax
  class WorkShowPresenter
    include ModelProxy
    include PresentsAttributes

    attr_accessor :solr_document, :current_ability, :request

    class_attribute :collection_presenter_class

    # modify this attribute to use an alternate presenter class for the collections
    self.collection_presenter_class = CollectionPresenter

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, :export_formats, :export_as, to: :solr_document

    # delegate fields from Hyrax::Works::Metadata to solr_document
    delegate :based_near_label, :related_url, :depositor, :identifier, :resource_type,
             :keyword, :itemtype, :admin_set, to: :solr_document

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context. Used so
    #                                  the GraphExporter knows what URLs to draw.
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    def page_title
      title.first
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :to_s,
             to: :solr_document

    # Metadata Methods
    delegate :title, :date_created, :description,
             :creator, :contributor, :subject, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :license, :source, :rights_statement, :thumbnail_id, :representative_id,
             :rendering_ids, :member_of_collection_ids, to: :solr_document

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

    # @return [Boolean] render the UniversalViewer
    def universal_viewer?
      representative_id.present? &&
        representative_presenter.present? &&
        representative_presenter.image? &&
        Hyrax.config.iiif_image_server?
    end

    # @return FileSetPresenter presenter for the representative FileSets
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||=
        begin
          result = member_presenters([representative_id]).first
          return nil if result.try(:id) == id
          if result.respond_to?(:representative_presenter)
            result.representative_presenter
          else
            result
          end
        end
    end

    # Get presenters for the collections this work is a member of via the member_of_collections association.
    # @return [Array<CollectionPresenter>] presenters
    def member_of_collection_presenters
      PresenterFactory.build_for(ids: member_of_collection_ids,
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
      current_ability.can?(:read, id) ? to_s : 'File'
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

    def editor?
      current_ability.can?(:edit, solr_document)
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
      grouped = member_of_collection_presenters.group_by(&:model_name).transform_keys { |key| key.to_s.underscore }
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
      Hyrax::Engine.routes.url_helpers.stats_work_path(self)
    end

    def model
      solr_document.to_model
    end

    delegate :member_presenters, :file_set_presenters, :work_presenters, to: :member_presenter_factory

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    # IIIF rendering linking property for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add a 'rendering' (eg. a link a download for the resource)
    #
    # @return [Array] array of rendering hashes
    def sequence_rendering
      renderings = []
      if solr_document.rendering_ids.present?
        solr_document.rendering_ids.each do |file_set_id|
          renderings << manifest_helper.build_rendering(file_set_id)
        end
      end
      renderings.flatten
    end

    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @return [Array] array of metadata hashes
    def manifest_metadata
      metadata = []
      Hyrax.config.iiif_metadata_fields.each do |field|
        metadata << {
          'label' => I18n.t("simple_form.labels.defaults.#{field}"),
          'value' => Array.wrap(send(field))
        }
      end
      metadata
    end

    private

      def manifest_helper
        @manifest_helper ||= ManifestHelper.new(request.base_url)
      end

      def featured?
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
        MemberPresenterFactory.new(solr_document, current_ability, request)
      end

      def graph
        GraphExporter.new(solr_document, request).fetch
      end
  end
end
