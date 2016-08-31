module Sufia
  module Admin
    class StrategiesController < Flipflop::StrategiesController
      before_action do
        authorize! :manage, Sufia::Feature
      end

      # TODO: we could remove this if we used an isolated engine
      def features_url
        sufia.admin_features_path
      end
    end
  end
end
