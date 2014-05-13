class Collection < ActiveFedora::Base
  include Hydra::Collection
  # override the default Hydra properties so we don't get a prefix deprecation warning.
  has_metadata "properties", type: Worthwhile::PropertiesDatastream
  include CurationConcern::CollectionModel
  include Hydra::Collections::Collectible

  def can_be_member_of_collection?(collection)
    collection == self ? false : true
  end
end
