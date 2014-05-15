module Worthwhile
  module FilesController
    extend ActiveSupport::Concern

    included do
      include Worthwhile::ThemedLayoutController
      with_themed_layout '1_column'
      load_and_authorize_resource class: Worthwhile::GenericFile
      helper_method :curation_concern
      include Worthwhile::ParentContainer
    end

    def curation_concern
      @generic_file
    end

    # routed to /files/new
    def new
      @batch_noid = Sufia::Noid.noidify(Sufia::IdService.mint)
    end

    # routed to /files/:id/edit
    def edit
      @generic_file.initialize_fields
      @groups = current_user.groups
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
        json_error "Error! No file for upload", 'unknown file', :status => :unprocessable_entity
      elsif (empty_file?(file))
        json_error "Error! Zero Length File!", file.original_filename
      else
        process_file(file)
      end
    rescue RSolr::Error::Http => error
      logger.error "GenericFilesController::create rescued #{error.class}\n\t#{error.to_s}\n #{error.backtrace.join("\n")}\n\n"
      json_error "Error occurred while creating generic file."
    ensure
      # remove the tempfile (only if it is a temp file)
      file.tempfile.delete if file.respond_to?(:tempfile)
    end

    # routed to /files/:id
    def show
    end

    def destroy
      @generic_file.destroy
      redirect_to [:curation_concern, @generic_file.batch], notice: "The file has been deleted."
    end

    # routed to /files/:id (PUT)
    def update

      if params.has_key?(:revision) and params[:revision] !=  @generic_file.content.latest_version.versionID
        Sufia::GenericFile::Actions.revert_content(@generic_file, params[:revision], datastream_id, current_user)
      elsif params.has_key?(:filedata)
        Sufia::GenericFile::Actions.update_content(@generic_file, params[:filedata], datastream_id, current_user)
        Sufia.queue.push(CharacterizeJob.new(@generic_file.pid)) # TODO put this in the Actions.update_content
      else
        # only update metadata if there is a generic_file object which is not the case for version updates
        update_metadata if params[:generic_file]
      end

      if @generic_file.save
        @generic_file.record_version_committer(current_user)
        redirect_to [:curation_concern, @generic_file], notice:
          "The file #{view_context.link_to(@generic_file, [main_app, :curation_concern, @generic_file])} has been updated."
      else
        render action: 'edit'
      end
    rescue RSolr::Error::Http => error
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

    def _prefixes
      # This allows us to use the unauthorized and form_permission template in curation_concern/base
      @_prefixes ||= super + ['curation_concern/base']
    end

    def empty_file?(file)
      (file.respond_to?(:tempfile) && file.tempfile.size == 0) || (file.respond_to?(:size) && file.size == 0)
    end

    def process_file(file)
      update_metadata_from_upload_screen
      create_metadata(@generic_file)
      if Sufia::GenericFile::Actions.create_content(@generic_file, file, file.original_filename, datastream_id, current_user)
        Sufia.queue.push(CharacterizeJob.new(@generic_file.pid)) # TODO put this in the Actions.create_content
        respond_to do |format|
          format.html {
            if request.xhr?
              render json: [@generic_file.to_jq_upload], content_type: 'text/html', layout: false
            else
              redirect_to [:curation_concern, @generic_file.batch]
            end
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
      Sufia::GenericFile::Actions.create_metadata(file, current_user, params[:parent_id])
    end
  end
end
