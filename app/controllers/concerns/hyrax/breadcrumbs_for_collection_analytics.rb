# frozen_string_literal: true
module Hyrax
  module BreadcrumbsForCollectionAnalytics
    extend ActiveSupport::Concern
    include Hyrax::Breadcrumbs

    included do
      before_action :build_breadcrumbs, only: [:index, :show]
    end

    def add_breadcrumb_for_controller
      add_breadcrumb 'Collection Report', hyrax.admin_analytics_collection_reports_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'show'
        add_breadcrumb "#{params[:id]}", hyrax.admin_analytics_collection_reports_path(params[:id]), mark_active_action
      end
    end

    def mark_active_action
      { "aria-current" => "page" }
    end
  end
end