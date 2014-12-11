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
      prepend_before_filter :normalize_identifier, except: [:index, :create, :new]
      load_resource only: [:audit]
      load_and_authorize_resource except: [:index, :audit]
    end

    # routed to /files/new
    def new
      #@batch_noid = Sufia::Noid.noidify(Sufia::IdService.mint)
      @batch_noid = Batch.create.noid
    end

    # routed to /files/:id/edit
    def edit
      @generic_file.initialize_fields
      @groups = current_user.groups
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
      elsif params.has_key? :filedata
        update_file
      elsif params.has_key? :generic_file
        update_metadata
      end

      if success
        redirect_to sufia.edit_generic_file_path(tab: params[:redirect_tab]), notice:
          render_to_string(partial: 'generic_files/asset_updated_flash', locals: { generic_file: @generic_file })
      else
        render action: 'edit'
      end
    rescue => error
      flash[:error] = error.message
      logger.error "GenericFilesController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    protected

    def audit_service
      Sufia::GenericFileAuditService.new(@generic_file)
    end

    def wants_to_revert?
      params.has_key?(:revision) && params[:revision] != @generic_file.content.latest_version.to_s
    end

    def actor
      @actor ||= Sufia::GenericFile::Actor.new(@generic_file, current_user)
    end

    def update_version
      actor.revert_content(params[:revision])
    end

    def update_file
      actor.update_content(params[:filedata], datastream_id)
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      actor.update_metadata(params[:generic_file], params[:visibility])
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
      update_metadata_from_upload_screen
      actor.create_metadata(params[:batch_id])
      if actor.create_content(file, file.original_filename, datastream_id)
        respond_to do |format|
          format.html {
            render json: [@generic_file.to_jq_upload],
            content_type: 'text/html',
            layout: false
          }
          format.json {
            render json: [@generic_file.to_jq_upload]
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

    # The name of the datastream where we store the file data
    def datastream_id
      'content'
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    # called when creating or updating metadata
    def update_metadata_from_upload_screen
      # Relative path is set by the jquery uploader when uploading a directory
      @generic_file.relative_path = params[:relative_path] if params[:relative_path]
      @generic_file.on_behalf_of = params[:on_behalf_of] if params[:on_behalf_of]
    end
  end
end
