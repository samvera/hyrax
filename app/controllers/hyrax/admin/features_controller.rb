module Hyrax
  module Admin
    class FeaturesController < Flipflop::FeaturesController
      layout 'admin'

      before_action do
        authorize! :manage, Hyrax::Feature
      end

      # overriding so we can have a layout https://github.com/voormedia/flipflop/issues/18
      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
        add_breadcrumb t(:'hyrax.admin.sidebar.settings'), hyrax.admin_features_path
        @feature_set = Flipflop::FeaturesController::FeaturesPresenter.new(Flipflop::FeatureSet.current)
        render
      end
    end
  end
end
