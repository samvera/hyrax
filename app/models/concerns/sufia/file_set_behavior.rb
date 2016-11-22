module Sufia
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Sufia::WithEvents
    include Sufia::BasicMetadata
    include Hydra::Works::FileSetBehavior
    include Hydra::Works::VirusCheck
    include Sufia::FileSet::Characterization
    include Hydra::WithDepositor
    include Serializers
    include Sufia::Noid
    include Sufia::FileSet::Derivatives
    include Permissions
    include Sufia::FileSet::Indexing
    include Sufia::FileSet::BelongsToWorks
    include Sufia::FileSet::Querying
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
