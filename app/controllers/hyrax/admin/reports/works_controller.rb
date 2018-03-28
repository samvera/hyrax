module Hyrax
  class Admin::Reports::WorksController < ApplicationController
    with_themed_layout 'dashboard'

    def status
      authorize! :read, Hyrax::Statistics
      # TODO: not yet implemented, an idea is to do the form submission and data gathering
      # similar to controllers/concerns/hyrax/admin/stats_behavior.rb
      stats_filters = params.fetch(:stats_filters, {})

      @presenter = Hyrax::Admin::WorkStatusReportPresenter.new(stats_filters, nil)

      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb "#{t(:'hyrax.admin.sidebar.works')} #{t(:'hyrax.admin.sidebar.status')} #{t(:'hyrax.admin.sidebar.statistics')}", hyrax.status_admin_reports_works_path
    end

    def attributes; end

    def activity; end
  end
end
