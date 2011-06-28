# Include this into models to specify that the descMetadata datastream contains basic MODS metadata
# 
# Explicitly declares:
#   descMetadata datastream using Hydra::ModsArticle Terminology
#
module Hydra::ModelMixins::ModsObject
  
  def self.included(klazz)
    # Uses the Hydra MODS Basic profile for tracking descriptive metadata
    klazz.has_metadata :name => "descMetadata", :type => Hydra::ModsArticle
    
    # Ensure that objects assert the modsObject cModel
    # klazz.relationships << :has_model => "info:fedora/hydra-cModel:modsObject"
  end
  
end