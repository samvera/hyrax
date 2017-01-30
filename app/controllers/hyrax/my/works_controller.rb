module Hyrax
  module My
    class WorksController < MyController
      def search_builder_class
        Hyrax::MyWorksSearchBuilder
      end

      def index
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
