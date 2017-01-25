module Hyrax
  module My
    class CollectionsController < MyController
      def search_builder_class
        Hyrax::MyCollectionsSearchBuilder
      end

      def index
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
