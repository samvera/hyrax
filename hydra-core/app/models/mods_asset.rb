# An EXAMPLE   Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata (currently "Article" is the MODS exemplar)
class ModsAsset < ActiveFedora::Base
  
  ## Convenience methods for manipulating the rights metadata datastream
  include Hydra::AccessControls::Permissions
  
  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
end
