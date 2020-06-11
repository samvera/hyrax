# frozen_string_literal: true
module Hyrax
  module Admin
    class FeaturesController < Flipflop::FeaturesController
      with_themed_layout 'dashboard'

      before_action do
        authorize! :manage, Hyrax::Feature
      end

      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
        add_breadcrumb t(:'hyrax.admin.sidebar.technical'), hyrax.admin_features_path
        super
      end
    end
  end
end
