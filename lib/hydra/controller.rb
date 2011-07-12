module Hydra::Controller
  def self.included(base)
    base.helper :hydra_assets
  end
end