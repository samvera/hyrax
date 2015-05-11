module Sufia
  autoload :VirusFoundError, 'sufia/models/virus_found_error'

  module GenericFile
    extend ActiveSupport::Concern
    include Hydra::Works::GenericFileBehavior
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Export
    include Sufia::GenericFile::Characterization
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::Derivatives
    include Sufia::GenericFile::Metadata
    include Sufia::GenericFile::Content
    include Sufia::GenericFile::VirusCheck
    include Sufia::GenericFile::FullTextIndexing
    include Hydra::Collections::Collectible
    include Sufia::GenericFile::Batches
    include Sufia::GenericFile::Indexing
    include Sufia::GenericFile::Works
  end
end
