module CurationConcerns
  module FilesController
    extend ActiveSupport::Concern

    included do
      include CurationConcerns::ThemedLayoutController
      with_themed_layout '1_column'
      load_and_authorize_resource class: CurationConcerns::GenericFile
      helper_method :curation_concern
      include CurationConcerns::ParentContainer
    end

    def curation_concern
      @generic_file
    end

    # routed to /files/new
    def new
    end

    # routed to /files/:id/edit
    def edit
      # @generic_file.initialize_fields
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
      success = if wants_to_revert?
        actor.revert_content(params[:revision])
      elsif params.has_key? :files
        actor.update_content(params[:files].first, datastream_id)
      elsif params.has_key? :generic_file
        update_metadata
      end
      if success
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

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      file_attributes = CurationConcerns::Forms::GenericFileEditForm.model_attributes(attributes)
      actor.update_metadata(file_attributes, attributes[:visibility])
    end

    protected

    def wants_to_revert?
      params.has_key?(:revision) && params[:revision] != @generic_file.content.latest_version.label
    end

    def actor
      @actor ||= ::CurationConcern::GenericFileActor.new(@generic_file, current_user, attributes)
    end

    def attributes
      # params.fetch(:generic_file, {}).dup  # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
      params.fetch(:generic_file, {}).permit!.dup  # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
    end

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
      actor.create_metadata(parent_id)
      if actor.create_content(file, file.original_filename, datastream_id, file.content_type)
        respond_to do |format|
          format.html {
            if request.xhr?
              render 'jq_upload', formats: 'json', content_type: 'text/html'
            else
              redirect_to [:curation_concern, @generic_file.batch]
            end
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

    # The name of the datastream where we store the file data
    def datastream_id
      'content'
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata_from_upload_screen
      # Relative path is set by the jquery uploader when uploading a directory
      @generic_file.relative_path = params[:relative_path] if params[:relative_path]
    end

  end
end
