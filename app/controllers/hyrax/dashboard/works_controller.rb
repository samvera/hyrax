module Hyrax
  module Dashboard
    ## Shows a list of all works to the admins
    class WorksController < Hyrax::My::WorksController
      before_action :ensure_admin!

      # Search builder for a list of works
      # Override of Blacklight::RequestBuilders
      def search_builder_class
        Hyrax::WorksSearchBuilder
      end

      private

        def ensure_admin!
          # Even though the user can view this admin set, they may not be able to view
          # it on the admin page.
          authorize! :read, :admin_dashboard
        end

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
