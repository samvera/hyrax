class Collection < ActiveFedora::Base
  include Hydra::Collection
  include CurationConcern::CollectionModel
  include Hydra::Collections::Collectible
  include CurationConcern::WithBasicMetadata

  # override the default Hydra properties so we don't get a prefix deprecation warning.
  has_metadata "properties", type: Worthwhile::PropertiesDatastream

end
