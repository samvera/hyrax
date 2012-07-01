# Include this module into any of your Controller classes to add Hydra functionality
#
# The primary function of this module is to mix in a number of other Hydra Modules, including 
#   Hydra::AccessControlsEnforcement
#
# @example 
#  class CustomHydraController < ApplicationController  
#    include Hydra::Controller
#  end
#
# will move to lib/hydra/controller/controller_behavior in release 5.x
module Hydra::Controller
  autoload :AssetsControllerBehavior, 'hydra/controller/assets_controller_behavior'
  autoload :ControllerBehavior, 'hydra/controller/controller_behavior'
  autoload :RepositoryControllerBehavior, 'hydra/controller/repository_controller_behavior'
  autoload :UploadBehavior, 'hydra/controller/upload_behavior'
  autoload :FileAssetsBehavior, 'hydra/controller/file_assets_behavior'

  extend ActiveSupport::Concern
  
  included do
    ActiveSupport::Deprecation.warn("Hydra::Controller has been renamed Hydra::Controller::ControllerBehavior.")
    include Hydra::Controller::ControllerBehavior
  end
end
