module Hyrax
  class AdminController < ApplicationController
    include Blacklight::Base
    before_action :authorize_user
    layout 'admin'

    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
      @presenter = AdminDashboardPresenter.new
      @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
    end

    def workflows
      @status_list = Hyrax::Workflow::StatusListService.new(current_user)
    end

    private

      def authorize_user
        authorize! :read, :admin_dashboard
      end
  end
end
