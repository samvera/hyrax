module Hyrax
  module My
    class SharesController < MyController
      def search_builder_class
        Hyrax::MySharesSearchBuilder
      end

      def index
        super
        @selected_tab = 'shared'
      end

      protected

        def search_action_url(*args)
          hyrax.dashboard_shares_url(*args)
        end
    end
  end
end
