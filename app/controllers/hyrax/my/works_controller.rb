module Hyrax
  module My
    class WorksController < MyController
      def search_builder_class
        Hyrax::MyWorksSearchBuilder
      end

      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.works'), hyrax.dashboard_works_path

        super
        @selected_tab = 'works'
      end

      protected

        def search_action_url(*args)
          hyrax.dashboard_works_url(*args)
        end

        # The url of the "more" link for additional facet values
        def search_facet_path(args = {})
          hyrax.dashboard_works_facet_path(args[:id])
        end
    end
  end
end
