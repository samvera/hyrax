module Hyrax
  module Admin
    module StatsBehavior
      extend ActiveSupport::Concern
      included do
        layout 'dashboard'
      end

      def show
        authorize! :read, Hyrax::Statistics
        stats_filters = params.fetch(:stats_filters, {})
        limit = params.fetch(:limit, "5").to_i
        @presenter = AdminStatsPresenter.new(stats_filters, limit)
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.statistics'), hyrax.admin_stats_path
      end
    end
  end
end
