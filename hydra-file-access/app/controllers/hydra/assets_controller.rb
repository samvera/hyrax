require 'deprecation'
class Hydra::AssetsController < ApplicationController
  extend Deprecation

  self.deprecation_horizon = 'hydra-head 5.x'
    include Hydra::Controller::AssetsControllerBehavior

  def initialize *args
    Deprecation.warn(Hydra::AssetsController, "Hydra::AssetsController is deprecated and will be removed from #{self.class.deprecation_horizon}")
    super
  end
end
