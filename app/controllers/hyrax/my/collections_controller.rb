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
    end
  end
end
