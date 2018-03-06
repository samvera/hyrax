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
        @work_rows = Hyrax::CollectionsCountService.new(self, Hyrax::AdminSetSearchBuilder, ::Collection).search_results_with_work_count(:read)
        render 'show_admin'
      else
        @presenter = Dashboard::UserPresenter.new(current_user, view_context, params[:since])
        render 'show_user'
      end
    end

    def update_collections
      @collections = Hyrax::CollectionsCountService.new(self, Hyrax::AdminSetSearchBuilder, ::Collection).search_results_with_work_count(:read)
      @collections.sort_by { |coll| coll[params[:sort_type]].to_s }.reverse!
      @collection_rows = Kaminari.paginate_array(@collections).page(params[:page]).per(10)

      render json: { rows: render_to_string('hyrax/dashboard/_analytics_collections_ajax', layout: false, locals: { collection_rows: @collection_rows}) }
    end

    def repository_growth
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::RepositoryGrowthPresenter.new(params[:time_period])
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
