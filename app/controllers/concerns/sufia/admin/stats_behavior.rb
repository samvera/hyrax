module Sufia
  module Admin
    module StatsBehavior
      extend ActiveSupport::Concern
      included do
        layout 'admin'
      end

      def show
        authorize! :read, Sufia::Statistics
        stats_filters = params.fetch(:stats_filters, {})
        limit = params.fetch(:limit, "5").to_i
        @presenter = AdminStatsPresenter.new(stats_filters, limit)
        add_breadcrumb t(:'sufia.controls.home'), root_path
        add_breadcrumb t(:'sufia.toolbar.admin.menu'), sufia.admin_path
        add_breadcrumb t(:'sufia.admin.sidebar.statistics'), sufia.admin_stats_path
      end
    end
  end
end
