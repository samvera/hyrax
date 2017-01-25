module Sufia
  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      before_action :build_breadcrumbs, only: [:edit, :show]
      with_themed_layout '1_column'
      # include the link_to_remove_from_collection view helper methods
      helper CurationConcerns::CollectionsHelper
      self.presenter_class = Sufia::CollectionPresenter
      self.form_class = Sufia::Forms::CollectionForm
    end

    protected

      def after_destroy(id)
        respond_to do |wants|
          wants.html do
            redirect_to sufia.dashboard_collections_path,
                        notice: "Collection #{id} was successfully deleted"
          end
          wants.json do
            render json: { id: id, description: "Collection #{id} was successfully deleted" }
          end
        end
      end

      def after_destroy_error(id)
        respond_to do |wants|
          wants.html do
            flash[:notice] = "Collection #{id} could not be deleted"
            render :edit, status: :unprocessable_entity
          end
          wants.json do
            render json: { id: id, description: "Collection #{id} could not be deleted" },
                   status: :unprocessable_entity
          end
        end
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('sufia.dashboard.my.collections'), sufia.dashboard_collections_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'edit'.freeze
          add_breadcrumb I18n.t("sufia.collection.browse_view"), main_app.collection_path(params["id"])
        when 'show'.freeze
          add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
        end
      end
  end
end
