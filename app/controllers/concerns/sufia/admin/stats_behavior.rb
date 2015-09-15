module Sufia
  module Admin
    module StatsBehavior
      extend ActiveSupport::Concern

      included do
        include Sufia::Admin::DepositorStats
      end

      def index
        # initialize the presenter
        @presenter = AdminStatsPresenter.new(params.fetch(:users_stats, {}), params.fetch([:dep_count], "5").to_i)

        # get deposit stats
        @presenter.deposit_stats = params.fetch(:deposit_stats, {})
        @presenter.depositors = depositors(@presenter.deposit_stats)

        render 'index'
      end
    end
  end
end
