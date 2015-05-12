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
      self.edit_form_class = Sufia::Forms::GenericFileEditForm
      self.presenter_class = Sufia::GenericFilePresenter
    end

    # routed to /files/new
    def new
      @batch_id = ActiveFedora::Noid::Service.new.mint
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

    # routed to /files (POST)
    def create
      create_from_upload(params)
    end

    def create_from_upload(params)
      # check error condition No files
      return json_error("Error! No file to save") if !params.has_key?(:files)

      file = params[:files].detect {|f| f.respond_to?(:original_filename) }
      if !file
        json_error "Error! No file for upload", 'unknown file', status: :unprocessable_entity
      elsif (empty_file?(file))
        json_error "Error! Zero Length File!", file.original_filename
      elsif (!terms_accepted?)
        json_error "You must accept the terms of service!", file.original_filename
      else
        process_file(file)
      end
    rescue => error
      logger.error "GenericFilesController::create rescued #{error.class}\n\t#{error.to_s}\n #{error.backtrace.join("\n")}\n\n"
      json_error "Error occurred while creating generic file."
    ensure
      # remove the tempfile (only if it is a temp file)
      file.tempfile.delete if file.respond_to?(:tempfile)
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
      Sufia::VersionListPresenter.new(@generic_file.content.versions.all)
    end

    def edit_form
      edit_form_class.new(@generic_file)
    end

    def audit_service
      Sufia::GenericFileAuditService.new(@generic_file)
    end

    def wants_to_revert?
      params.has_key?(:revision) && params[:revision] != Sufia::VersioningService.latest_version_of(@generic_file.content).label
    end

    def wants_to_upload_new_version?
      has_file_data = params.has_key?(:filedata)
      on_version_tab = params[:redirect_tab] == 'versions'

      has_file_data || (on_version_tab && !wants_to_revert?)
    end

    def actor
      @actor ||= Sufia::GenericFile::Actor.new(@generic_file, current_user)
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
      file_attributes = edit_form_class.model_attributes(params[:generic_file])
      actor.update_metadata(file_attributes, params[:visibility])
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

      update_metadata_from_upload_screen
      actor.create_metadata(params[:batch_id], params[:work_id])
      if actor.create_content(file, file.original_filename, file.content_type)
        respond_to do |format|
          format.html {
            render 'jq_upload', formats: 'json', content_type: 'text/html'
          }
          format.json {
            render 'jq_upload'
          }
        end
      else
        msg = @generic_file.errors.full_messages.join(', ')
        flash[:error] = msg
        json_error "Error creating generic file: #{msg}"
      end
    end

    # override this method if you want to change how the terms are accepted on upload.
    def terms_accepted?
      params[:terms_of_service] == '1'
    end

    # override this method if you need to initialize more complex RDF assertions (b-nodes)
    # @deprecated use @generic_file.initialize_fields instead
    def initialize_fields(file)
      file.initialize_fields
    end

    ActiveSupport::Deprecation.deprecate_methods(FilesControllerBehavior, :initialize_fields)

    # this is provided so that implementing application can override this behavior and map params to different attributes
    # called when creating or updating metadata
    def update_metadata_from_upload_screen
      # Relative path is set by the jquery uploader when uploading a directory
      @generic_file.relative_path = params[:relative_path] if params[:relative_path]
      @generic_file.on_behalf_of = params[:on_behalf_of] if params[:on_behalf_of]
    end
  end
end
