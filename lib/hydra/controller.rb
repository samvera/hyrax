# Adds behaviors that Hydra needs all controllers to have. (mostly view helpers)
module Hydra::Controller
  def self.included(base)
    base.helper :hydra_assets
    base.helper :hydra_fedora_metadata
  end
end