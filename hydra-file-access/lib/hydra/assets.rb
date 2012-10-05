module Hydra
  module Assets
    extend ActiveSupport::Concern
    included do
      include Hydra::Controller::AssetsControllerBehavior
    end
  end
end
