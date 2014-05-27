class Collection < ActiveFedora::Base
  include CurationConcern::CollectionModel

  # override the default Hydra properties so we don't get a prefix deprecation warning.
  has_metadata "properties", type: Worthwhile::PropertiesDatastream
end
