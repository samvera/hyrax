module Sufia
  module Admin
    class FeaturesController < Flip::FeaturesController
      layout 'admin'
      before_action do
        authorize! :manage, Sufia::Feature
        add_breadcrumb  'Home', root_path
        add_breadcrumb  'Repository Dashboard', sufia.admin_path
        add_breadcrumb  'Settings', sufia.admin_features_path
      end
    end
  end
end
