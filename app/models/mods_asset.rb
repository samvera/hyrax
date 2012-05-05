# An EXAMPLE   Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata (currently "Article" is the MODS exemplar)
class ModsAsset < ActiveFedora::Base
  
  # declares a rightsMetadata datastream with type Hydra::Datastream::RightsMetadata
  #  basically, it is another expression of
  #  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  include Hydra::ModelMixins::CommonMetadata

  ## Convenience methods for manipulating the rights metadata datastream
  include Hydra::ModelMixins::RightsMetadata
  
  # declares a descMetadata datastream with type Hydra::Datastream::ModsArticle
  #  basically, it is another expression of
  #  has_metadata :name => "descMetadata", :type => Hydra::Datastream::ModsArticle
  include Hydra::ModelMixins::ModsObject
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods

  # adds file_objects methods
  include ActiveFedora::FileManagement

  
end
