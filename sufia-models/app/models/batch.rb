class Batch < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::RightsMetadata
  include Sufia::ModelMethods
  include Sufia::Noid

  has_metadata :name => "descMetadata", :type => BatchRdfDatastream

  belongs_to :user, :property => "creator"
  has_many :generic_files, :property => :is_part_of

  delegate :title, :to => :descMetadata, multiple: true
  delegate :creator, :to => :descMetadata, multiple: true
  delegate :part, :to => :descMetadata, multiple: true
  delegate :status, :to => :descMetadata, multiple: true

  def self.find_or_create(pid)
    begin
      Batch.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      Batch.create({pid: pid})
    end
  end

  def to_solr(solr_doc={}, opts={})
    super(solr_doc, opts)
    solr_doc[Solrizer.solr_name('noid', Sufia::GenericFile.noid_indexer)] = noid
    return solr_doc
  end
end
