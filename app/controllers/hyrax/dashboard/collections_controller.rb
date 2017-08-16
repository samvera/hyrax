module Hyrax
  module Dashboard
    ## Shows a list of all collections to the admins
    class CollectionsController < Hyrax::My::CollectionsController
      include Hyrax::Dashboard::CollectionsControllerBehavior
      include BreadcrumbsForCollections
      layout 'dashboard'

      # load_and_authorize_resource except: [:index, :show, :create], instance_name: :collection
      load_and_authorize_resource except: [:index, :create], instance_name: :collection

      before_action :ensure_admin!, only: :index # index for All Collections; see also Hyrax::My::CollectionsController #index for My Collections

      # Renders a JSON response with a list of files in this collection
      # This is used by the edit form to populate the thumbnail_id dropdown
      def files
        result = form.select_files.map do |label, id|
          { id: id, text: label }
        end
        render json: result
      end

      def search_builder_class
        Hyrax::CollectionSearchBuilder
      end

      private

        def ensure_admin!
          # Even though the user can view this collection, they may not be able to view
          # it on the admin page.
          authorize! :read, :admin_dashboard
        end

        def search_action_url(*args)
          hyrax.dashboard_collections_url(*args)
        end

        def form
          @form ||= form_class.new(@collection, current_ability, repository)
        end
    end
  end
end
