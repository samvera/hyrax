module Sufia
  module Admin
    class StrategiesController < Flip::StrategiesController
      before_action do
        authorize! :manage, Feature
      end

      # TODO: we could remove this if we used an isolated engine
      def features_url
        sufia.admin_features_path
      end
    end
  end
end
