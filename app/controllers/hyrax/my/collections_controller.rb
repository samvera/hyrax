module Hyrax
  module My
    class CollectionsController < MyController
      def search_builder_class
        Hyrax::MyCollectionsSearchBuilder
      end

      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.collections'), hyrax.dashboard_collections_path

        super
        @selected_tab = 'collections'
      end

      protected

        def search_action_url(*args)
          hyrax.dashboard_collections_url(*args)
        end

        # The url of the "more" link for additional facet values
        def search_facet_path(args = {})
          hyrax.dashboard_collections_facet_path(args[:id])
        end
    end
  end
end
