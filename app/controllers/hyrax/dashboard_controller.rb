# frozen_string_literal: true
module Hyrax
  class DashboardController < ApplicationController
    include Blacklight::Base
    include Hyrax::Breadcrumbs
    with_themed_layout 'dashboard'
    before_action :authenticate_user!
    before_action :build_breadcrumbs, only: [:show]

    ##
    # @!attribute [rw] sidebar_partials
    #   @return [Hash]
    #
    # @example Add a custom partial to the tasks sidebar block
    #   Hyrax::DashboardController.sidebar_partials[:tasks] << "hyrax/dashboard/sidebar/custom_task"
    class_attribute :sidebar_partials
    self.sidebar_partials = { activity: [], configuration: [], repository_content: [], tasks: [] }

    def show
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::DashboardPresenter.new
        @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
        render 'show_admin'
      else
        @presenter = Dashboard::UserPresenter.new(current_user, view_context, params[:since])
        render 'show_user'
      end
    end
  end
end
