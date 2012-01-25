require "datastreams/fits_datastream"
require "datastreams/psu_dc_datastream"

class GenericFile < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "characterization", :type => FitsDatastream
  has_metadata :name => "descMetadata", :type => Psu::DcDatastream
  has_file_datastream :type=>FileContentDatastream

  delegate :contributor, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :title, :to => :descMetadata

end
