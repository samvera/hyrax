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
    extend Deprecation
    extend ActiveSupport::Concern
  
    included do
      # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
      has_metadata "rightsMetadata", type: Hydra::Datastream::RightsMetadata
      Deprecation.warn(CommonMetadata, "Hydra::ModelMixins::CommonMetadata is deprecated and will be removed in hydra-head 7.  Use Hydra::AccessControls::Permissions instead.", caller(1))
    end
  end
end
