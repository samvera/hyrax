require "psu-customizations"

class Batch < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "descMetadata", :type => BatchRdfDatastream

  belongs_to :user, :property => "creator"
  has_many :generic_files, :property => "part"

  delegate :title, :to => :descMetadata
  delegate :creator, :to => :descMetadata
  delegate :part, :to => :descMetadata
end
