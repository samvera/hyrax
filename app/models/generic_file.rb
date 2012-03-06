require "psu-customizations"

class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => GammaRDFDatastream
  has_file_datastream :type => FileContentDatastream

  belongs_to :folder, :property => "isPartOf"

  delegate :related_url, :to => :descMetadata
  delegate :based_near, :to => :descMetadata
  delegate :part_of, :to => :descMetadata
  delegate :contributor, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :title, :to => :descMetadata
  delegate :description, :to => :descMetadata
  delegate :publisher, :to => :descMetadata
  delegate :date_created, :to => :descMetadata
  delegate :date_uploaded, :to => :descMetadata
  delegate :date_modified, :to => :descMetadata
  delegate :subject, :to => :descMetadata
  delegate :language, :to => :descMetadata
  delegate :date, :to => :descMetadata
  delegate :rights, :to => :descMetadata
  delegate :resource_type, :to => :descMetadata
  delegate :format, :to => :descMetadata
  delegate :identifier, :to => :descMetadata
  delegate :format_label, :to => :characterization
  delegate :mime_type, :to => :characterization
  delegate :file_size, :to => :characterization
  delegate :last_modified, :to => :characterization
  delegate :filename, :to => :characterization
  delegate :original_checksum, :to => :characterization
  delegate :well_formed, :to => :characterization
  delegate :file_title, :to => :characterization
  delegate :file_author, :to => :characterization
  delegate :page_count, :to => :characterization

  before_save :characterize

  ## Extract the metadata from the content datastream and record it in the characterization datastream
  def characterize
    if content.changed?
      characterization.content = content.extract_metadata
    end
  end
  
  def to_solr(solr_doc={})
    super(solr_doc)
    solr_doc["label_t"] = self.label
    return solr_doc
  end
  
  def label=(new_label)
    @inner_object.label = new_label
    if self.title.empty?
      title = new_label
    end
  end
  
end
