module Sufia
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::CollectionsControllerBehavior

    included do
      include Sufia::Breadcrumbs

      before_action :has_access?, except: :show
      before_action :build_breadcrumbs, only: [:edit, :show]
      layout "sufia-one-column"
      # include the link_to_remove_from_collection view helper methods
      helper CurationConcerns::CollectionsHelper
    end

    protected

      def presenter_class
        Sufia::CollectionPresenter
      end

      def query_collection_members
        # TODO: Should this be moved to curation_concerns
        flash[:notice] = nil if flash[:notice] == "Select something first"
        super
      end

      def after_destroy(id)
        respond_to do |format|
          format.html { redirect_to sufia.dashboard_collections_path, notice: 'Collection was successfully deleted.' }
          format.json { render json: { id: id }, status: :destroyed, location: @collection }
        end
      end
  end
end
