# frozen_string_literal: true
module Hyrax
  module Admin
    module UsersControllerBehavior
      extend ActiveSupport::Concern
      include Blacklight::SearchContext
      included do
        before_action :ensure_admin!
        with_themed_layout 'dashboard'
      end

      # Display admin menu list of users
      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.users.index.title'), hyrax.admin_users_path
        @presenter = Hyrax::Admin::UsersPresenter.new
      end

      private

      def ensure_admin!
        authorize! :read, :admin_dashboard
      end
    end
  end
end
