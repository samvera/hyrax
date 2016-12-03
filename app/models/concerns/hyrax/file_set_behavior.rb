module Hyrax
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Hyrax::WithEvents
    include Hyrax::BasicMetadata
    include Hydra::Works::FileSetBehavior
    include Hydra::Works::VirusCheck
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
    include RequiredMetadata
    include Naming
    include Hydra::AccessControls::Embargoable
    include GlobalID::Identification

    included do
      attr_accessor :file
      self.human_readable_type = 'File'
    end

    def representative_id
      to_param
    end

    def thumbnail_id
      to_param
    end

    # Cast to a SolrDocument by querying from Solr
    def to_presenter
      CatalogController.new.fetch(id).last
    end
  end
end
