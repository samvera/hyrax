module Hyrax
  class DashboardController < ApplicationController
    include Blacklight::Base
    with_themed_layout 'dashboard'
    before_action :authenticate_user!

    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::DashboardPresenter.new
        @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
        render 'show_admin'
      else
        @presenter = Dashboard::UserPresenter.new(current_user, view_context, params[:since])
        render 'show_user'
      end
    end

    def repository_growth
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::RepositoryGrowthPresenter.new(params[:type_value])
        render json: @presenter
      end
    end

    def repository_object_counts
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::RepositoryObjectPresenter.new(params[:type_value])
        render json: @presenter
      end
    end
  end
end
