module Sufia
  module Admin
    class StrategiesController < Flip::StrategiesController
      before_action do
        authorize! :manage, Feature
      end
    end
  end
end
