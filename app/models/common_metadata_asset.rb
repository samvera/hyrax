# @deprecated This is intended as an EXAMPLE of mixing in model behavior and will be moved to hydra-wiki documentation.  This will be removed no later than 6.x
# EXAMPLE of a basic model that conforms to Hydra commonMetadata cModel and has basic MODS metadata (currently "Article" is the MODS exemplar)
class CommonMetadataAsset < ActiveFedora::Base
  
  # declares a rightsMetadata datastream with type Hydra::Datastream::RightsMetadata
  #  basically, it is another expression of
  #  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::CommonMetadata
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
end

