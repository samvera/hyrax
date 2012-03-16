require "psu-customizations"

class Batch < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMethods

  has_metadata :name => "descMetadata", :type => BatchRDFDatastream

  belongs_to :user, :property => "batch_creator"
  has_many :generic_files, :property => "part"

  delegate :batch_title, :to => :descMetadata
  delegate :batch_creator, :to => :descMetadata
  delegate :part, :to => :descMetadata
end
