# A Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata (currently "Article" is the MODS exemplar)
class ModsAsset < ActiveFedora::Base
  
  # declares a rightsMetadata datastream with type Hydra::RightsMetadata
  #  basically, it is another expression of
  #  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata
  include Hydra::ModelMixins::CommonMetadata
  
  # declares a descMetadata datastream with type Hydra::ModsArticle
  #  basically, it is another expression of
  #  has_metadata :name => "descMetadata", :type => Hydra::ModsArticle
  include Hydra::ModelMixins::ModsObject
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
end