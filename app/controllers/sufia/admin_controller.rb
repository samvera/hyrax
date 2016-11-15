module Sufia
  class AdminController < ApplicationController
    include Blacklight::Base
    layout 'admin'
    def show
      authorize! :read, :admin_dashboard
      add_breadcrumb t(:'sufia.controls.home'), root_path
      add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
      @presenter = AdminDashboardPresenter.new
      @admin_set_rows = Sufia::AdminSetService.new(self).search_results_with_work_count(:read)
    end
  end
end
