require 'hydra'
# An EXAMPLE   Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata (currently "Article" is the MODS exemplar)
class ModsAsset < ActiveFedora::Base
  
  # declares a rightsMetadata datastream with type Hydra::Datastream::RightsMetadata
  #  basically, it is another expression of
  #  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::CommonMetadata

  ## Convenience methods for manipulating the rights metadata datastream
  include Hydra::ModelMixins::RightsMetadata
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
end
