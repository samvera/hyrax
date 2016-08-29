module Sufia
  class AdminController < ApplicationController
    layout 'admin'
    def show
      authorize! :read, :admin_dashboard
      add_breadcrumb  'Home', root_path
      add_breadcrumb  'Repository Dashboard', sufia.admin_path
      @presenter = AdminDashboardPresenter.new
    end
  end
end
