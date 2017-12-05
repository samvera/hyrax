module Hyrax
  class FileSetsController < ApplicationController
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include Hyrax::Breadcrumbs
    include Hyrax::ResourceController

    before_action :authenticate_user!, except: [:show, :citation, :stats]
    before_action :build_breadcrumbs, only: [:show, :edit, :stats]
    # provides the help_text view method
    helper PermissionsHelper

    helper_method :curation_concern
    include Hyrax::ParentContainer
    copy_blacklight_config_from(::CatalogController)

    class_attribute :show_presenter, :change_set_class
    self.show_presenter = Hyrax::FileSetPresenter
    self.resource_class = ::FileSet
    self.change_set_persister = Hyrax::FileSetChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    # A little bit of explanation, CanCan(Can) sets the @file_set via the .load_and_authorize_resource
    # method. However the interface for various CurationConcern modules leverages the #curation_concern method
    # Thus we have file_set and curation_concern that are aliases for each other.
    attr_accessor :file_set
    alias curation_concern file_set
    private :file_set=
    alias curation_concern= file_set=
    private :curation_concern=
    helper_method :file_set

    # routed to /files/:id
    def show
      respond_to do |wants|
        wants.html { presenter }
        wants.json { presenter }
        additional_response_formats(wants)
      end
    end

    def after_delete_success(_change_set, parent)
      redirect_to [main_app, parent], notice: 'The file has been deleted.'
    end

    def destroy
      @change_set = build_change_set(find_resource(params[:id]))
      parent = Hyrax::Queries.find_parents(resource: @change_set.resource).first
      authorize! :destroy, @change_set.resource
      change_set_persister.buffer_into_index do |persist|
        persist.delete(change_set: @change_set)
      end
      after_delete_success(@change_set, parent)
    end

    # routed to /files/:id/stats
    def stats
      authorize! :stats, find_resource(params[:id])
      @stats = FileUsage.new(params[:id])
    end

    # routed to /files/:id/citation
    def citation
      authorize! :citation, find_resource(params[:id])
    end

    private

      # Returns a FileUploadChangeSet if they have created or updated a file
      def change_set_class
        #   curation_concern.relative_path = params[:relative_path] if params[:relative_path]
        if action_name == 'create' || (action_name == 'update' && params[:file_set] && params[:file_set].key?(:files))
          FileUploadChangeSet
        elsif wants_to_revert?
          RevertFileChangeSet
        else
          Hyrax::FileSetChangeSet
        end
      end

      def change_set_persister
        if change_set_class == RevertFileChangeSet
          return Hyrax::RevertFileChangeSetPersister.new(
            metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
            storage_adapter: Valkyrie.config.storage_adapter
          )
        end
        self.class.change_set_persister
      end

      def after_create_error(_obj, change_set)
        if change_set.has_file?
          render_json_response(response_type: :unprocessable_entity,
                               options: { errors: change_set.errors.to_h,
                                          description: t('hyrax.api.unprocessable_entity.empty_file') })
        else
          render_json_response(response_type: :bad_request,
                               options: { message: change_set.errors[:files].first,
                                          description: 'missing file' })
        end
      end

      def after_create_success(resource, _change_set)
        respond_to do |format|
          format.html do
            if request.xhr?
              render 'jq_upload', formats: 'json', content_type: 'text/html'
            else
              redirect_to [main_app, resource.parent]
            end
          end
          format.json do
            render 'jq_upload', status: :created, location: polymorphic_path([main_app, resource])
          end
        end
      end

      def after_update_success(curation_concern, _change_set)
        respond_to do |wants|
          wants.html do
            redirect_to [main_app, curation_concern], notice: "The file #{view_context.link_to(curation_concern, [main_app, curation_concern])} has been updated."
          end
          wants.json do
            @presenter = show_presenter.new(curation_concern, current_ability)
            render :show, status: :ok, location: polymorphic_path([main_app, curation_concern])
          end
        end
      end

      def after_update_error(curation_concern, _change_set)
        respond_to do |wants|
          wants.html do
            flash[:error] = "There was a problem processing your request."
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
        end
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'edit'.freeze
          add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
        when 'show'.freeze
          add_breadcrumb presenter.parent.to_s, main_app.polymorphic_path(presenter.parent)
          add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
        end
      end

      # Override of Blacklight::RequestBuilders
      def search_builder_class
        Hyrax::FileSetSearchBuilder
      end

      def presenter
        @presenter ||= begin
          _, document_list = search_results(params)
          curation_concern = document_list.first
          raise CanCan::AccessDenied unless curation_concern
          show_presenter.new(curation_concern, current_ability, request)
        end
      end

      def wants_to_revert?
        params.key?(:revision) && params[:revision] != curation_concern.latest_content_version.label
      end

      # Override this method to add additional response formats to your local app
      def additional_response_formats(_); end

      def file_set_params
        params.require(:file_set).permit(
          :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo, :visibility_during_lease, :lease_expiration_date, :visibility_after_lease, :visibility, title: []
        )
      end

      # This allows us to use the unauthorized and form_permission template in hyrax/base,
      # while prefering our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['hyrax/base']
      end

      def json_error(error, name = nil, additional_arguments = {})
        args = { error: error }
        args[:name] = name if name
        render additional_arguments.merge(json: [args])
      end
  end
end
