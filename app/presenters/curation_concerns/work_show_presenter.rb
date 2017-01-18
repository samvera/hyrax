module CurationConcerns
  class WorkShowPresenter
    include ModelProxy
    include PresentsAttributes
    attr_accessor :solr_document, :current_ability, :request

    class_attribute :collection_presenter_class, :file_presenter_class, :work_presenter_class

    # modify this attribute to use an alternate presenter class for the collections
    self.collection_presenter_class = CollectionPresenter

    # modify this attribute to use an alternate presenter class for the files
    self.file_presenter_class = FileSetPresenter

    # modify this attribute to use an alternate presenter class for the child works
    self.work_presenter_class = self

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, :export_formats, :export_as, to: :solr_document

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    def page_title
      title.first
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id, :to_s,
             to: :solr_document

    # Metadata Methods
    delegate :title, :date_created, :date_modified, :date_uploaded, :description,
             :creator, :contributor, :subject, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :rights, :source, :thumbnail_id, :representative_id,
             :member_of_collection_ids, to: :solr_document

    # @return [Array<FileSetPresenter>] presenters for the orderd_members that are FileSets
    def file_set_presenters
      @file_set_presenters ||= member_presenters(ordered_ids & file_set_ids)
    end

    def workflow
      @workflow ||= WorkflowPresenter.new(solr_document, current_ability)
    end

    def inspect_work
      @inspect_workflow ||= InspectWorkPresenter.new(solr_document, current_ability)
    end

    # @return FileSetPresenter presenter for the representative FileSets
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||=
        begin
          result = member_presenters([representative_id]).first
          if result.respond_to?(:representative_presenter)
            result.representative_presenter
          else
            result
          end
        end
    end

    # @return [Array<WorkShowPresenter>] presenters for the ordered_members that are not FileSets
    def work_presenters
      @work_presenters ||= member_presenters(ordered_ids - file_set_ids, work_presenter_class)
    end

    # @param [Array<String>] ids a list of ids to build presenters for
    # @param [Class] presenter_class the type of presenter to build
    # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
    def member_presenters(ids = ordered_ids, presenter_class = composite_presenter_class)
      PresenterFactory.build_presenters(ids, presenter_class, *presenter_factory_arguments)
    end

    def composite_presenter_class
      CompositePresenterFactory.new(file_presenter_class, work_presenter_class, ordered_ids & file_set_ids)
    end

    # Get presenters for the collections this work is a member of via the member_of_collections association.
    # @return [Array<CollectionPresenter>] presenters
    def member_of_collection_presenters
      PresenterFactory.build_presenters(member_of_collection_ids, collection_presenter_class,
                                        *presenter_factory_arguments)
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

    private

      def graph
        GraphExporter.new(solr_document, request).fetch
      end

      def presenter_factory_arguments
        [current_ability, request]
      end

      # TODO: Extract this to ActiveFedora::Aggregations::ListSource
      def ordered_ids
        @ordered_ids ||= begin
                           ActiveFedora::SolrService.query("proxy_in_ssi:#{id}",
                                                           rows: 10_000,
                                                           fl: "ordered_targets_ssim")
                                                    .flat_map { |x| x.fetch("ordered_targets_ssim", []) }
                         end
      end

      # These are the file sets that belong to this work, but not necessarily
      # in order.
      # Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
      def file_set_ids
        @file_set_ids ||= begin
                            ActiveFedora::SolrService.query("{!field f=has_model_ssim}FileSet",
                                                            rows: 10_000,
                                                            fl: ActiveFedora.id_field,
                                                            fq: "{!join from=ordered_targets_ssim to=id}id:\"#{id}/list_source\"")
                                                     .flat_map { |x| x.fetch(ActiveFedora.id_field, []) }
                          end
      end
  end
end
