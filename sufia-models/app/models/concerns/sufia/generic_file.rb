module Sufia
  autoload :VirusFoundError, 'sufia/models/virus_found_error'

  module GenericFile
    extend ActiveSupport::Concern
    include Sufia::ModelMethods
    include Sufia::Noid
    include Sufia::GenericFile::MimeTypes
    include Sufia::GenericFile::Export
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
    include Sufia::GenericFile::Batches
    include Sufia::GenericFile::Indexing
  end
end
