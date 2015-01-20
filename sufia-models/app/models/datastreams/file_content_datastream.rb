class FileContentDatastream < ActiveFedora::File
  include Hydra::Derivatives::ExtractMetadata
  include Sufia::FileContent::Versions
end
