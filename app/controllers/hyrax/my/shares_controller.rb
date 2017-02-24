module Hyrax
  module My
    class SharesController < MyController
      def search_builder_class
        Hyrax::MySharesSearchBuilder
      end

      def index
        super
      end

      protected

        def search_action_url(*args)
          hyrax.dashboard_shares_url(*args)
        end

        # The url of the "more" link for additional facet values
        def search_facet_path(args = {})
          hyrax.dashboard_shares_facet_path(args[:id])
        end
    end
  end
end
