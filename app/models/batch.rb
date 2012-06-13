class Batch < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Dil::RightsMetadata
  include PSU::ModelMethods
  include PSU::Noid

  has_metadata :name => "descMetadata", :type => BatchRdfDatastream

  belongs_to :user, :property => "creator"
  has_many :generic_files, :property => :is_part_of

  delegate :title, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :part, :to => :descMetadata

  def self.find_or_create(pid)
     begin
        @batch = Batch.find(pid)
     rescue ActiveFedora::ObjectNotFoundError
        @batch = Batch.create({pid: pid})
     end     
  end
  
  def to_solr(solr_doc={})
    super(solr_doc)
    solr_doc["noid_s"] = noid
    return solr_doc
  end

end
