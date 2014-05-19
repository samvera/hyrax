class Collection < ActiveFedora::Base
  include Hydra::Collection
  # override the default Hydra properties so we don't get a prefix deprecation warning.
  has_metadata "properties", type: Worthwhile::PropertiesDatastream
  include CurationConcern::CollectionModel
  include Hydra::Collections::Collectible

  def can_be_member_of_collection?(collection)
    collection == self ? false : true
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    index_collection_pids(solr_doc)
    return solr_doc
  end
end
