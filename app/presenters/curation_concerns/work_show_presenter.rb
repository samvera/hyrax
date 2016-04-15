module CurationConcerns
  class WorkShowPresenter
    include ModelProxy
    include PresentsAttributes
    attr_accessor :solr_document, :current_ability

    class_attribute :collection_presenter_class, :file_presenter_class

    # modify this attribute to use an alternate presenter class for the collections
    self.collection_presenter_class = CollectionPresenter

    # modify this attribute to use an alternate presenter class for the files
    self.file_presenter_class = FileSetPresenter

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    def initialize(solr_document, current_ability)
      @solr_document = solr_document
      @current_ability = current_ability
    end

    def page_title
      solr_document.title
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id, :to_s,
             to: :solr_document

    # Metadata Methods
    delegate :title, :date_created, :date_modified, :date_uploaded, :description,
             :creator, :contributor, :subject, :publisher, :language, :embargo_release_date,
             :lease_expiration_date, :rights, to: :solr_document

    # @return [Array<FileSetPresenter>] presenters for the orderd_members that are FileSets
    def file_set_presenters
      @file_set_presenters ||= member_presenters(ordered_ids & file_set_ids)
    end

    # @deprecated
    # @return [Array<FileSetPresenter>] presenters for the orderd_members that are FileSets
    def file_presenters
      Deprecation.warn WorkShowPresenter, "file_presenters is deprecated and will be removed in CurationConcerns 1.0. Use file_set_presenters or member_presenters instead."
      member_presenters
    end

    # @return [Array<FileSetPresenter>] presenters for the ordered_members (not filtered by class)
    def member_presenters(ids = ordered_ids)
      PresenterFactory.build_presenters(ids,
                                        file_presenter_class,
                                        current_ability)
    end

    # @return [Array<CollectionPresenter>] presenters for the collections that this work is a member of
    def collection_presenters
      PresenterFactory.build_presenters(in_collection_ids,
                                        collection_presenter_class,
                                        current_ability)
    end

    private

      # @return [Array<String>] ids of the collections that this work is a member of
      def in_collection_ids
        ActiveFedora::SolrService.query("{!field f=ordered_targets_ssim}#{id}",
                                        fl: 'proxy_in_ssi')
                                 .map { |x| x.fetch('proxy_in_ssi') }
      end

      # TODO: Extract this to ActiveFedora::Aggregations::ListSource
      def ordered_ids
        ActiveFedora::SolrService.query("proxy_in_ssi:#{id}",
                                        fl: "ordered_targets_ssim")
                                 .flat_map { |x| x.fetch("ordered_targets_ssim", []) }
      end

      # These are the file sets that belong to this work, but not necessarily
      # in order.
      def file_set_ids
        ActiveFedora::SolrService.query("{!field f=has_model_ssim}FileSet",
                                        fl: "id",
                                        fq: "{!join from=ordered_targets_ssim to=id}id:\"#{id}/list_source\"")
                                 .flat_map { |x| x.fetch("id", []) }
      end
  end
end
