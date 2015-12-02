module Sufia
  module Admin
    module StatsBehavior
      extend ActiveSupport::Concern

      included do
        include Sufia::Admin::DepositorStats
      end

      def index
        stats_filters = params.fetch(:stats_filters, {})

        # initialize the presenter
        @presenter = AdminStatsPresenter.new(stats_filters, params.fetch(:limit, "5").to_i)

        # get deposit stats
        @presenter.deposit_stats = stats_filters
        @presenter.depositors = depositors(stats_filters)

        render 'index'
      end
    end
  end
end
