# frozen_string_literal: true
module Hyrax
  module Admin
    ##
    # @example using a custom presenter and stats services
    #   class MyStatsController < ApplicationController
    #     include Hyrax::Admin::StatsBehavior
    #
    #     self.admin_stats_presenter = MyCustomStatsPresenter
    #     self.admin_stats_services = { by_depositor:      CustomDepositorService,
    #                                   depositor_summary: CustomSummaryService }
    #     # see AdminStatsPresenter#initialize for supported services
    #   end
    #
    module StatsBehavior
      extend ActiveSupport::Concern
      included do
        with_themed_layout 'dashboard'

        class_attribute :admin_stats_presenter, :admin_stats_services
        self.admin_stats_presenter = AdminStatsPresenter
        self.admin_stats_services  = {}
      end

      def show
        authorize! :read, Hyrax::Statistics
        stats_filters = params.fetch(:stats_filters, {})
        limit = params.fetch(:limit, "5").to_i
        @presenter = build_presenter(stats_filters, limit)
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.statistics'), hyrax.admin_stats_path
      end

      private

      def build_presenter(stats_filters, limit)
        presenter_class = self.class.admin_stats_presenter
        services_opts   = self.class.admin_stats_services

        presenter_class.new(stats_filters, limit, **services_opts)
      end
    end
  end
end
