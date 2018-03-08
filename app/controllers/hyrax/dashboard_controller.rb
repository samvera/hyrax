module Hyrax
  class DashboardController < ApplicationController
    include Blacklight::Base
    include Hyrax::Breadcrumbs
    with_themed_layout 'dashboard'
    before_action :authenticate_user!
    before_action :build_breadcrumbs, only: [:show]

    def show
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::DashboardPresenter.new
        @admin_set_rows = Hyrax::AdminSetService.new(self, Hyrax::AdminSetSearchBuilder).search_results_with_work_count(:read)
        @collection_rows = Hyrax::CollectionsCountService.new(self, Hyrax::AdminSetSearchBuilder, ::Collection).search_results_with_work_count(:read)
        render 'show_admin'
      else
        @presenter = Dashboard::UserPresenter.new(current_user, view_context, params[:since])
        render 'show_user'
      end
    end

    def repository_growth
      return unless can? :read, :admin_dashboard
      @repo_growth = Hyrax::Admin::RepositoryGrowthPresenter.new(params[:time_period])
      render json: @repo_growth
    end

    def repository_object_counts
      return unless can? :read, :admin_dashboard
      @repo_objects = Hyrax::Admin::RepositoryObjectPresenter.new(params[:type_value])
      render json: @repo_objects
    end

    def update_works_list
      if can? :read, :admin_dashboard
        @work_rows = Hyrax::WorksCountService.new(self, Hyrax::WorksSearchBuilder, nil, params).search_results_with_work_count(:read)
        render json: @work_rows
      end
    end
  end
end
