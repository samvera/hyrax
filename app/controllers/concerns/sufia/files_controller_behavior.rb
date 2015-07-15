module Sufia
  module FilesController
    extend ActiveSupport::Autoload
    autoload :BrowseEverything
    autoload :LocalIngestBehavior
    autoload :UploadCompleteBehavior
  end
  module FilesControllerBehavior
    extend ActiveSupport::Concern
    extend Sufia::FilesController::UploadCompleteBehavior
    include Sufia::Breadcrumbs

    included do
      include Hydra::Controller::ControllerBehavior
      include Blacklight::Configurable
      include Sufia::FilesController::BrowseEverything
      include Sufia::FilesController::LocalIngestBehavior
      extend Sufia::FilesController::UploadCompleteBehavior

      layout "sufia-one-column"

      self.copy_blacklight_config_from(CatalogController)

      # Catch permission errors
      rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
        if exception.action == :edit
          redirect_to(sufia.url_for({action: 'show'}), alert: "You do not have sufficient privileges to edit this document")
        elsif current_user and current_user.persisted?
          redirect_to root_url, alert: exception.message
        else
          session["user_return_to"] = request.url
          redirect_to new_user_session_url, alert: exception.message
        end
      end

      # actions: audit, index, create, new, edit, show, update,
      #          destroy, permissions, citation, stats
      before_filter :authenticate_user!, except: [:show, :citation, :stats]
      before_filter :has_access?, except: [:show]
      before_filter :build_breadcrumbs, only: [:show, :edit, :stats]
      load_resource only: [:audit]
      load_and_authorize_resource except: [:index, :audit]

      class_attribute :edit_form_class, :presenter_class
      self.edit_form_class = CurationConcerns::Forms::GenericFileEditForm
      self.presenter_class = Sufia::GenericFilePresenter
    end

    # routed to /files/new
    def new
      @batch_id = ActiveFedora::Noid::Service.new.mint
      @work_id = params[:parent_id]
    end

    # routed to /files/:id/edit
    def edit
      set_variables_for_edit_form
    end

    # routed to /files/:id/stats
    def stats
      @stats = FileUsage.new(params[:id])
    end

    # routed to /files/:id (DELETE)
    def destroy
      actor.destroy
      redirect_to self.class.destroy_complete_path(params), notice:
        render_to_string(partial: 'generic_files/asset_deleted_flash', locals: { generic_file: @generic_file })
    end

    # routed to /files/:id/citation
    def citation
    end

    # routed to /files/:id
    def show
      respond_to do |format|
        format.html {
          @events = @generic_file.events(100)
          @presenter = presenter
          @audit_status = audit_service.human_readable_audit_status
        }
        format.endnote { render text: @generic_file.export_as_endnote }
      end
    end

    # routed to /files/:id/audit (POST)
    def audit
      render json: audit_service.audit
    end

    # routed to /files/:id (PUT)
    def update
      success = if wants_to_revert?
        update_version
      elsif wants_to_upload_new_version?
        update_file
      elsif params.has_key? :generic_file
        update_metadata
      elsif params.has_key? :visibility
        update_visibility
      end

      if success
        redirect_to sufia.edit_generic_file_path(tab: params[:redirect_tab]), notice:
          render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      else
        flash[:error] ||= 'Update was unsuccessful.'
        set_variables_for_edit_form
        render action: 'edit'
      end
    end

    protected

    def set_variables_for_edit_form
      @form = edit_form
      @groups = current_user.groups
      @version_list = version_list
    end

    def presenter
      presenter_class.new(@generic_file)
    end

    def version_list
      all_versions = @generic_file.original_file.nil? ? [] : @generic_file.original_file.versions.all
      Sufia::VersionListPresenter.new(all_versions)
    end

    def edit_form
      edit_form_class.new(@generic_file)
    end

    def audit_service
      CurationConcerns::GenericFileAuditService.new(@generic_file)
    end

    def wants_to_revert?
      params.has_key?(:revision) && params[:revision] != CurationConcerns::VersioningService.latest_version_of(@generic_file.original_file).label
    end

    def wants_to_upload_new_version?
      has_file_data = params.has_key?(:filedata)
      on_version_tab = params[:redirect_tab] == 'versions'

      has_file_data || (on_version_tab && !wants_to_revert?)
    end

    def actor
      @actor ||= CurationConcerns::GenericFileActor.new(@generic_file, current_user)
    end

    def update_version
      actor.revert_content(params[:revision])
    end

    def update_file
      if params[:filedata]
        actor.update_content(params[:filedata])
      else
        flash[:error] = 'Please select a file.'
        false
      end
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      actor.update_metadata(file_attributes, unfiltered_attributes)
    end

    def update_visibility
      actor.update_metadata({}, params[:visibility])
    end

    def json_error(error, name=nil, additional_arguments={})
      args = {error: error}
      args[:name] = name if name
      render additional_arguments.merge(json: [args])
    end

    def empty_file?(file)
      (file.respond_to?(:tempfile) && file.tempfile.size == 0) || (file.respond_to?(:size) && file.size == 0)
    end

    def process_file(file)
      Batch.find_or_create(params[:batch_id])
      super(file)
    end

    # override this method if you want to change how the terms are accepted on upload.
    def terms_accepted?
      params[:terms_of_service] == '1'
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    # called when creating or updating metadata
    def update_metadata_from_upload_screen
      @generic_file.on_behalf_of = params[:on_behalf_of] if params[:on_behalf_of]
      super
    end

    # The attributes appropriate for updating generic_file objects
    def file_attributes
      edit_form_class.model_attributes(params[:generic_file])
    end

    # Returns a duplicate of the :generic_file params
    # *Danger*: permits all attributes in params[:generic_file], so could present security vulnerabilities if you do something like generic_file.attributes=unfiltered_attributes
    # Does not filter out attributes like :visibility, which is not returned by file_attributes, so that the actor can use that info
    def unfiltered_attributes
      params.fetch(:generic_file, {}).permit!.dup  # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
    end

  end
end
