# An EXAMPLE   Basic Model for Assets that conform to Hydra commonMetadata cModel and have basic MODS metadata (currently "Article" is the MODS exemplar)
class ModsAsset < ActiveFedora::Base
  extend Deprecation

  def initialize(*)
    Deprecation.warn(ModsAsset, "ModsAsset is deprecated and will be removed in hydra-head 10")
    super
  end

  ## Convenience methods for manipulating the rights metadata datastream
  include Hydra::AccessControls::Permissions

  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
end
