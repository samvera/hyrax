module Hyrax
  module My
    class WorksController < MyController
      def search_builder_class
        Hyrax::MyWorksSearchBuilder
      end

      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.works'), hyrax.my_works_path

        super
      end

      protected

        def search_action_url(*args)
          hyrax.my_works_url(*args)
        end

        # The url of the "more" link for additional facet values
        def search_facet_path(args = {})
          hyrax.my_dashboard_works_facet_path(args[:id])
        end
    end
  end
end
