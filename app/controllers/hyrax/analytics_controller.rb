module Hyrax
  class AnalyticsController < ApplicationController
    include Blacklight::Base
    before_action :authenticate_user!

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
      return unless can? :read, :admin_dashboard
      @work_rows = Hyrax::WorksCountService.new(self, Hyrax::AnalyticsWorksSearchBuilder, params).search_results_with_work_count(:read)
      render json: @work_rows
    end
  end
end
