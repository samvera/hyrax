module Sufia
  class AdminController < ApplicationController
    layout 'admin'
    def show
      authorize! :read, :admin_dashboard
      add_breadcrumb t(:'sufia.controls.home'), root_path
      add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
      @presenter = AdminDashboardPresenter.new
    end
  end
end
