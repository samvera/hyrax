module Hyrax
  class AdminController < ApplicationController
    include Blacklight::Base
    before_action :ensure_admin!
    layout 'admin'

    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
      @presenter = Hyrax::Admin::DashboardPresenter.new
      @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
    end

    private

      def ensure_admin!
        authorize! :read, :admin_dashboard
      end
  end
end
