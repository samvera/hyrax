require "psu-customizations"

class Folder < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "descMetadata", :type => ActiveFedora::DCRDFDatastream

  belongs_to :user, :property => "creator"
  has_many :generic_files, :property => "has_part"

  delegate :title, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :has_part, :to => :descMetadata
end
