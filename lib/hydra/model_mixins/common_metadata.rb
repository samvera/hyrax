# Include this into models that you want to conform to the Hydra commonMetadata cModel
# See https://wiki.duraspace.org/display/hydra/Hydra+objects%2C+content+models+%28cModels%29+and+disseminators#Hydraobjects%2Ccontentmodels%28cModels%29anddisseminators-models
#
# Explicitly declares:
#   rightsMetadata datastream using Hydra::RightsMetadata Terminology
#
# Does not explicitly declare:
#   descMetadata datastream -- should be declared by a more specific mixin like Hydra::ModelMixins::ModsObject
#   DC datastream -- Handled by ActiveFedora::Base
#   RELS-EXT datastream -- Handled by ActiveFedora::Base & ActiveFedora::RelsExtDatastream
#   optional datastreams (contentMetadata, technicalMetadata, provenanceMetadata, sourceMetadata)
#
module Hydra::ModelMixins
  module CommonMetadata
  
    def self.included(klazz)
      # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
      klazz.has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata
    
      # Ensure that objects assert the commonMetadata cModel
      # klazz.relationships << :has_model => "info:fedora/hydra-cModel:commonMetadata"
    end
  end
end