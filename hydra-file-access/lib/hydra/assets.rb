module Hydra
  module Assets
    extend ActiveSupport::Concern
    require 'hydra/controller/assets_controller_behavior'
    include Hydra::Controller::AssetsControllerBehavior
  end
end
