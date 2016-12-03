module Hyrax
  class AdminController < ApplicationController
    include Blacklight::Base
    layout 'admin'
    def show
      authorize! :read, :admin_dashboard
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
      @presenter = AdminDashboardPresenter.new
      @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
    end

    def workflows
      @status_list = Hyrax::Workflow::StatusListService.new(current_user)
    end
  end
end
