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
  end
end
