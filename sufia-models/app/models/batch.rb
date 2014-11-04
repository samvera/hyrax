class Batch < ActiveFedora::Base
  include Hydra::AccessControls::Permissions
  include Sufia::ModelMethods
  include Sufia::Noid

  belongs_to :user, property: "creator"
  has_many :generic_files, property: :is_part_of

  property :creator, predicate: RDF::DC.creator
  property :title, predicate: RDF::DC.title
  property :status, predicate: RDF::DC.type

  def self.find_or_create(id)
    begin
      Batch.find(id)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create(id: id)
    end
  end

  def to_solr(solr_doc={})
    super.tap do |solr_doc|
      solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
    end
  end
end
