# frozen_string_literal: true
module Hyrax
  module Dashboard
    ## Shows a list of all works to the admins
    class WorksController < Hyrax::My::WorksController
      # Search builder for a list of works
      # Override of Blacklight::RequestBuilders
      def search_builder_class
        Hyrax::Dashboard::WorksSearchBuilder
      end

      private

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
