module My
  class WorksController < MyController
    def search_builder_class
      Sufia::MyWorksSearchBuilder
    end

    def index
      super
      @selected_tab = 'works'
    end

    protected

      def search_action_url(*args)
        sufia.dashboard_works_url(*args)
      end

      # The url of the "more" link for additional facet values
      def search_facet_path(args = {})
        sufia.dashboard_works_facet_path(args[:id])
      end
  end
end
