# A Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata (currently "Article" is the MODS exemplar)
class CommonMetadataAsset < ActiveFedora::Base
  
  # declares a rightsMetadata datastream with type Hydra::Datastream::RightsMetadata
  #  basically, it is another expression of
  #  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::CommonMetadata
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
end

