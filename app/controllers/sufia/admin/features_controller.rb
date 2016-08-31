module Sufia
  module Admin
    class FeaturesController < Flipflop::FeaturesController
      layout 'admin'
      before_action do
        authorize! :manage, Sufia::Feature
        add_breadcrumb t(:'sufia.controls.home'), root_path
        add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
        add_breadcrumb t(:'sufia.admin.sidebar.settings'), sufia.admin_features_path
      end
    end
  end
end
