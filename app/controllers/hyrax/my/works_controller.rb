# frozen_string_literal: true
module Hyrax
  module My
    class WorksController < MyController
      # Define collection specific filter facets.
      def self.configure_facets
        configure_blacklight do |config|
          config.search_builder_class = Hyrax::My::WorksSearchBuilder
          config.add_facet_field "admin_set_sim", limit: 5
          config.add_facet_field "member_of_collections_ssim", limit: 5
        end
      end
      configure_facets

      class_attribute :create_work_presenter_class
      self.create_work_presenter_class = Hyrax::SelectTypeListPresenter

      def index
        # The user's collections for the "add to collection" form
        @user_collections = collections_service.search_results(:deposit)

        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.works'), hyrax.my_works_path
        managed_works_count
        @create_work_presenter = create_work_presenter_class.new(current_user)
        super
      end

      private

      def collections_service
        Hyrax::CollectionsService.new(self)
      end

      def search_action_url(*args)
        hyrax.my_works_url(*args)
      end

      # The url of the "more" link for additional facet values
      def search_facet_path(args = {})
        hyrax.my_dashboard_works_facet_path(args[:id])
      end

      def managed_works_count
        @managed_works_count = Hyrax::Works::ManagedWorksService.managed_works_count(scope: self)
      end
    end
  end
end
