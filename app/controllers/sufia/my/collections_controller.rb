module Sufia
  module My
    class CollectionsController < MyController
      def search_builder_class
        Sufia::MyCollectionsSearchBuilder
      end

      def index
        super
        @selected_tab = 'collections'
      end

      protected

        def search_action_url(*args)
          sufia.dashboard_collections_url(*args)
        end
    end
  end
end
