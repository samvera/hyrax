module CurationConcerns
  module FileSetBehavior
    extend ActiveSupport::Concern

    include Sufia::BasicMetadata
    include Hydra::Works::FileSetBehavior
    include Hydra::Works::VirusCheck
    include Sufia::FileSet::Characterization
    include Hydra::WithDepositor
    include Sufia::Serializers
    include Sufia::Noid
    include Sufia::FileSet::Derivatives
    include Sufia::Permissions
    include Sufia::FileSet::Indexing
    include Sufia::FileSet::BelongsToWorks
    include Sufia::FileSet::Querying
    include Sufia::HumanReadableType
    include Sufia::RequiredMetadata
    include Sufia::Naming
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
  end
end
