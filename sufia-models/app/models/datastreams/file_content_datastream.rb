class FileContentDatastream < ActiveFedora::Datastream
  include Hydra::Derivatives::ExtractMetadata
  include Sufia::FileContent::Versions
end
