module CurationConcerns
  # TODO The move of this file is in progress 
  autoload :VirusFoundError, 'curation_concerns/models/virus_found_error'

  module GenericFileBehaviors
    extend ActiveSupport::Concern
    include CurationConcerns::ModelMethods
    include CurationConcerns::Noid
    include Sufia::GenericFile::MimeTypes
    include CurationConcerns::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Trophies
    include Sufia::GenericFile::Featured
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Content
    include Sufia::GenericFile::Versions
    include Sufia::GenericFile::VirusCheck
    include Sufia::GenericFile::FullTextIndexing
    include Sufia::GenericFile::ProxyDeposit
    include Hydra::Collections::Collectible
    include CurationConcerns::GenericFile::Batches
    include Sufia::GenericFile::Indexing
  end
end
