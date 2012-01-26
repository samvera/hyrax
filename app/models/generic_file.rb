class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => Psu::DcDatastream
  has_file_datastream :type=>FileContentDatastream

  delegate :contributor, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :title, :to => :descMetadata

  before_save :characterize

  ## Extract the metadata from the content datastream and record it in the characterization datastream
  def characterize
    if content.changed?
      characterization.content = content.extract_metadata
    end
  end

end
