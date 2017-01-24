module My
  class SharesController < MyController
    def search_builder_class
      Sufia::MySharesSearchBuilder
    end

    def index
      super
      @selected_tab = 'shared'
    end

    protected

      def search_action_url(*args)
        sufia.dashboard_shares_url(*args)
      end

      # The url of the "more" link for additional facet values
      def search_facet_path(args = {})
        sufia.dashboard_shares_facet_path(args[:id])
      end
  end
end
