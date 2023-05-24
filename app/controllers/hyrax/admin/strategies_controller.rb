# frozen_string_literal: true
module Hyrax
  module Admin
    class StrategiesController < Flipflop::StrategiesController
      before_action do
        authorize! :manage, Hyrax::Feature
      end

      # TODO: we could remove this if we used an isolated engine
      def features_url(**_kargs)
        hyrax.admin_features_path
      end
    end
  end
end
