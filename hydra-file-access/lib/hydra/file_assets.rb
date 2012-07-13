# will move to lib/hydra/controller / file_assets_controller_behavior.rb in release 5.x
require 'deprecation'
module Hydra::FileAssets
  extend ActiveSupport::Concern
  
  included do
    Deprecation.warn Hydra::FileAssets, "Hydra::FileAssets was moved to Hydra::Controller::FileAssetsBehavior"
    include Hydra::Controller::FileAssetsBehavior
  end
end

