class Collection < ActiveFedora::Base
  include Hydra::Collection
  include CurationConcern::CollectionModel
  include Hydra::Collections::Collectible
  include CurationConcern::WithBasicMetadata
  include CurationConcern::WithGenericFiles

  # override the default Hydra properties so we don't get a prefix deprecation warning.
  has_metadata "properties", type: Worthwhile::PropertiesDatastream

  # override Hydra::Collection to add :solr_page_size
  has_and_belongs_to_many :members, property: :has_collection_member, class_name: "ActiveFedora::Base" , after_remove: :remove_member,
    solr_page_size: 150

end
