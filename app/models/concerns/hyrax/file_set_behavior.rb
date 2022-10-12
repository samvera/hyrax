# frozen_string_literal: true
module Hyrax
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Hyrax::WithEvents
    include Hydra::Works::FileSetBehavior
    include Hyrax::VirusCheck
    include Hyrax::FileSet::Characterization
    include Hydra::WithDepositor
    include Serializers
    include Hyrax::Noid
    include Hyrax::FileSet::Derivatives
    include Permissions
    include Hyrax::FileSet::Indexing
    include Hyrax::FileSet::BelongsToWorks
    include Hyrax::FileSet::Querying
    include HumanReadableType
    include CoreMetadata
    include Hyrax::BasicMetadata
    include Naming
    include Hydra::AccessControls::Embargoable
    include GlobalID::Identification

    included do
      attr_accessor :file
    end

    def representative_id
      to_param
    end

    def thumbnail_id
      to_param
    end

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      Deprecation.warn "Method #to_presenter will be removed in Hyrax 5.0. Use Hyrax::FileSetsController#presenter.solr_document or `@presenter.solr_document` from a view instead."
      CatalogController.new.fetch(id).last
    end
  end
end
