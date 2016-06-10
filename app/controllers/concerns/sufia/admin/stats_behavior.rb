module Sufia
  module Admin
    module StatsBehavior
      extend ActiveSupport::Concern

      def index
        authorize! :read, Sufia::Statistics
        stats_filters = params.fetch(:stats_filters, {})
        limit = params.fetch(:limit, "5").to_i
        @presenter = AdminStatsPresenter.new(stats_filters, limit)
      end
    end
  end
end
