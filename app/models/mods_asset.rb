# A Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata
class ModsAsset < ActiveFedora::Base
  include Hydra::ModelMixins::CommonMetadata
  include Hydra::ModelMixins::ModsObject
  include Hydra::ModelMethods
end