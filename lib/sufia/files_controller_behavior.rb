module Sufia
  module FilesController
    autoload :LocalIngestBehavior, 'sufia/files_controller/local_ingest_behavior'
    autoload :UploadCompleteBehavior, 'sufia/files_controller/upload_complete_behavior'
  end
  module FilesControllerBehavior
    extend ActiveSupport::Concern
    extend Sufia::FilesController::UploadCompleteBehavior

    included do
      include Hydra::Controller::ControllerBehavior
      include Blacklight::Configurable
      include Sufia::Noid # for normalize_identifier method
      include Sufia::FilesController::LocalIngestBehavior
      extend Sufia::FilesController::UploadCompleteBehavior

      layout "sufia-one-column"

      self.copy_blacklight_config_from(CatalogController)

      # Catch permission errors
      rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
        if exception.action == :edit
          redirect_to(sufia.url_for({:action=>'show'}), :alert => "You do not have sufficient privileges to edit this document")
        elsif current_user and current_user.persisted?
          redirect_to root_url, :alert => exception.message
        else
          session["user_return_to"] = request.url
          redirect_to new_user_session_url, :alert => exception.message
        end
      end

      # actions: audit, index, create, new, edit, show, update,
      #          destroy, permissions, citation, stats
      before_filter :authenticate_user!, :except => [:show, :citation]
      before_filter :has_access?, :except => [:show]
      prepend_before_filter :normalize_identifier, :except => [:index, :create, :new]
      load_resource :only=>[:audit]
      load_and_authorize_resource :except=>[:index, :audit]
    end

    # routed to /files/new
    def new
      @generic_file = ::GenericFile.new
      @batch_noid = Sufia::Noid.noidify(Sufia::IdService.mint)
    end

    # routed to /files/:id/edit
    def edit
      @generic_file.initialize_fields
      @groups = current_user.groups
    end

    # routed to /files/:id/stats
    def stats
      path = sufia.generic_file_path(Sufia::Noid.noidify(params[:id]))
      # Pull back results from GA, filter them for path, and hashify
      @created = DateTime.parse(::GenericFile.find(params[:id]).create_date)
      results_list = Sufia::UsageStatistics.profile.pageview(
        start_date: @created,
        end_date: DateTime.now,
        sort: 'date').for_path(path)
      @stats_json = Sufia::UsageStatistics.as_flot_json(results_list)
      @pageviews = Sufia::UsageStatistics.total_pageviews(results_list)
    end

    # routed to /files/:id (DELETE)
    def destroy
      pid = @generic_file.noid
      @generic_file.destroy
      Sufia.queue.push(ContentDeleteEventJob.new(pid, current_user.user_key))
      redirect_to self.class.destroy_complete_path(params), :notice => render_to_string(:partial=>'generic_files/asset_deleted_flash', :locals => { :generic_file => @generic_file })
    end

    # routed to /files (POST)
    def create
      if params[:local_file].present?
        perform_local_ingest
      elsif params[:selected_files].present?
        create_from_browse_everything(params)
      else
        create_from_upload(params)
      end
    end
    
    def create_from_browse_everything(params)
      params[:selected_files].each_pair do |index, file_info| 
        next if file_info.blank? || file_info["url"].blank?
        create_file_from_url(file_info["url"])
      end
      redirect_to self.class.upload_complete_path( params[:batch_id])
    end
    
    # Generic utility for creating GenericFile from a URL
    # Used in to import files using URLs from a file picker like browse_everything 
    def create_file_from_url(url, batch_id=nil)
      @generic_file = ::GenericFile.new
      @generic_file.import_url = url
      @generic_file.label = File.basename(url)
      create_metadata(@generic_file)
      Sufia.queue.push(ImportUrlJob.new(@generic_file.pid))
      return @generic_file
    end

    def create_from_upload(params)
      # check error condition No files
      return json_error("Error! No file to save") if !params.has_key?(:files)

      file = params[:files].detect {|f| f.respond_to?(:original_filename) }
      if !file
        json_error "Error! No file for upload", 'unknown file', :status => :unprocessable_entity
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
        }
        format.endnote { render :text => @generic_file.export_as_endnote }
      end
    end

    # routed to /files/:id/audit (POST)
    def audit
      render :json=>@generic_file.audit
    end

    # routed to /files/:id (PUT)
    def update
      version_event = false

      if params.has_key?(:revision) and params[:revision] !=  @generic_file.content.latest_version.versionID
        revision = @generic_file.content.get_version(params[:revision])
        @generic_file.add_file(revision.content, datastream_id, revision.label)
        version_event = true
        Sufia.queue.push(ContentRestoredVersionEventJob.new(@generic_file.pid, current_user.user_key, params[:revision]))
      end

      if params.has_key?(:filedata)
        file = params[:filedata]
        @generic_file.add_file(file, datastream_id, file.original_filename)
        version_event = true
      end

      # only update metadata if there is a generic_file object which is not the case for version updates
      update_metadata if params[:generic_file]

      #always save the file so the new version or metadata gets recorded
      if @generic_file.save
        # do not trigger an update event if a version event has already been triggered
        if version_event
          Sufia.queue.push(ContentNewVersionEventJob.new(@generic_file.pid, current_user.user_key)) if params.has_key?(:filedata)
        else
          Sufia.queue.push(ContentUpdateEventJob.new(@generic_file.pid, current_user.user_key))
        end
        @generic_file.record_version_committer(current_user)
        redirect_to sufia.edit_generic_file_path(:tab => params[:redirect_tab]), :notice => render_to_string(:partial=>'generic_files/asset_updated_flash', :locals => { :generic_file => @generic_file })
      else
        render action: 'edit'
      end
    rescue => error
      flash[:error] = error.message
      logger.error "GenericFilesController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    protected

    def json_error(error, name=nil, additional_arguments={})
      args = {:error => error}
      args[:name] = name if name
      render additional_arguments.merge({:json => [args]})
    end

    def empty_file?(file)
      (file.respond_to?(:tempfile) && file.tempfile.size == 0) || (file.respond_to?(:size) && file.size == 0)
    end

    def process_file(file)
      @generic_file = ::GenericFile.new
      update_metadata_from_upload_screen
      create_metadata(@generic_file)
      Sufia::GenericFile::Actions.create_content(@generic_file, file, file.original_filename, datastream_id, current_user)
      respond_to do |format|
        format.html {
          render :json => [@generic_file.to_jq_upload],
          :content_type => 'text/html',
          :layout => false
        }
        format.json {
          render :json => [@generic_file.to_jq_upload]
        }
      end
    rescue ActiveFedora::RecordInvalid => af
      flash[:error] = af.message
      json_error "Error creating generic file: #{af.message}"
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
    def update_metadata_from_upload_screen
      # Relative path is set by the jquery uploader when uploading a directory
      @generic_file.relative_path = params[:relative_path] if params[:relative_path]
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      @generic_file.attributes = @generic_file.sanitize_attributes(params[:generic_file])
      @generic_file.visibility = params[:visibility]
      @generic_file.date_modified = DateTime.now
    end

    def create_metadata(file)
      Sufia::GenericFile::Actions.create_metadata(file, current_user, params[:batch_id])
    end

  end
end
