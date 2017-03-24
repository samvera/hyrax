module Hyrax
  module Dashboard
    ## Shows a list of all collections to the admins
    class CollectionsController < Hyrax::My::CollectionsController
      before_action :ensure_admin!

      def search_builder_class
        Hyrax::CollectionSearchBuilder
      end

      private

        def ensure_admin!
          # Even though the user can view this admin set, they may not be able to view
          # it on the admin page.
          authorize! :read, :admin_dashboard
        end

        def search_action_url(*args)
          hyrax.dashboard_collections_url(*args)
        end
    end
  end
end
