module CurationConcerns
  module FileSetBehavior
    extend ActiveSupport::Concern
    include Hydra::Works::FileSetBehavior
    include Hydra::Works::VirusCheck
    include Hydra::Works::Characterization
    include Hydra::WithDepositor
    include CurationConcerns::Serializers
    include CurationConcerns::Noid
    include CurationConcerns::FileSet::Derivatives
    include CurationConcerns::Permissions
    include CurationConcerns::BasicMetadata
    include CurationConcerns::FileSet::FullTextIndexing
    include CurationConcerns::FileSet::Indexing
    include CurationConcerns::FileSet::BelongsToWorks
    include CurationConcerns::FileSet::BelongsToUploadSets
    include CurationConcerns::HumanReadableType
    include Hydra::AccessControls::Embargoable

    included do
      attr_accessor :file
    end

    def human_readable_type
      self.class.to_s.demodulize.titleize
    end

    def representative
      to_param
    end
  end
end
