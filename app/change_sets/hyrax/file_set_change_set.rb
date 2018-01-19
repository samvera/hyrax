# frozen_string_literals: true

module Hyrax
  class FileSetChangeSet < Valkyrie::ChangeSet
    property :title, multiple: true, required: true

    include FormWithPermissions

    delegate :embargo_id, :lease_id, to: :resource
    # TODO: Figure out where to persist these fields
    property :embargo_release_date, virtual: true
    property :lease_expiration_date, virtual: true
    property :visibility, virtual: true
    property :visibility_during_embargo, virtual: true
    property :visibility_after_embargo, virtual: true
    property :visibility_during_lease, virtual: true
    property :visibility_after_lease, virtual: true
    property :depositor
    class_attribute :terms
    self.terms = [:resource_type, :title, :creator, :contributor, :description,
                  :keyword, :license, :publisher, :date_created, :subject, :language,
                  :identifier, :based_near, :related_url,
                  :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
                  :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
                  :visibility]

    def prepopulate!
      prepopulate_permissions
      self
    end

    def version_list
      @version_list ||= begin
        [] # TODO: remove when we have versions

        # original = resource.original_file
        # Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
      end
    end

    def page_title
      if resource.persisted?
        [resource.to_s, "#{resource.human_readable_type} [#{resource.to_param}]"]
      else
        ["New #{resource.human_readable_type}"]
      end
    end

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      document_model.find(id)
    end

    def parent
      solr = Valkyrie::MetadataAdapter.find(:index_solr).connection
      results = solr.get('select', params: { q: "{!field f=member_ids_ssim}id-#{id}",
                                             qt: 'standard' })
      ::SolrDocument.new(results['response']['docs'].first)
    end

    private

      def document_model
        CatalogController.blacklight_config.document_model
      end
  end
end
