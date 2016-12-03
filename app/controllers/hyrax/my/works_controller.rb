module Hyrax
  module My
    class WorksController < MyController
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper

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
    end
  end
end
