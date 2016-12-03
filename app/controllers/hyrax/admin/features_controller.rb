module Hyrax
  module Admin
    class FeaturesController < Flipflop::FeaturesController
      layout 'admin'
      before_action do
        authorize! :manage, Hyrax::Feature
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
        add_breadcrumb t(:'hyrax.admin.sidebar.settings'), hyrax.admin_features_path
      end
    end
  end
end
