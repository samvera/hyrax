module CurationConcerns
  module GenericFilesControllerBehavior
    extend ActiveSupport::Concern

    included do
      include CurationConcerns::ThemedLayoutController
      with_themed_layout '1_column'
      load_and_authorize_resource class: ::GenericFile, except: :show
      helper_method :curation_concern
      include CurationConcerns::ParentContainer
      include Blacklight::Base
      include Hydra::Controller::SearchBuilder
      copy_blacklight_config_from(::CatalogController)
    end

    def curation_concern
      @generic_file
    end

    # routed to /files/new
    def new
    end

    # routed to /files/:id/edit
    def edit
      @groups = current_user.groups
    end

    # routed to /files (POST)
    def create
      create_from_upload(params)
    end

    def create_from_upload(params)
      # check error condition No files
      return json_error('Error! No file to save') unless params.key?(:generic_file) && params.fetch(:generic_file).key?(:files)

      file = params[:generic_file][:files].detect { |f| f.respond_to?(:original_filename) }
      if !file
        json_error 'Error! No file for upload', 'unknown file', status: :unprocessable_entity
      elsif empty_file?(file)
        json_error 'Error! Zero Length File!', file.original_filename
      else
        process_file(file)
      end
    rescue RSolr::Error::Http => error
      logger.error "GenericFilesController::create rescued #{error.class}\n\t#{error}\n #{error.backtrace.join("\n")}\n\n"
      json_error 'Error occurred while creating generic file.'
    ensure
      # remove the tempfile (only if it is a temp file)
      file.tempfile.delete if file.respond_to?(:tempfile)
    end

    # routed to /files/:id
    def show
      _, document_list = search_results(params, [:add_access_controls_to_solr_params, :find_one, :only_generic_files])
      curation_concern = document_list.first
      raise CanCan::AccessDenied unless curation_concern
      @presenter = show_presenter.new(curation_concern, current_ability)
    end

    # Gives the class of the show presenter. Override this if you want
    # to use a different presenter.
    def show_presenter
      CurationConcerns::GenericFilePresenter
    end

    def destroy
      actor.destroy
      redirect_to [main_app, :curation_concerns, @generic_file.generic_works.first], notice: 'The file has been deleted.'
    end

    # routed to /files/:id (PUT)
    def update
      success = if wants_to_revert?
                  actor.revert_content(params[:revision])
                elsif params.key?(:generic_file)
                  if params[:generic_file].key?(:files)
                    actor.update_content(params[:generic_file][:files].first)
                  else
                    update_metadata
                  end
                end
      if success
        redirect_to [main_app, :curation_concerns, @generic_file], notice:
          "The file #{view_context.link_to(@generic_file, [main_app, :curation_concerns, @generic_file])} has been updated."
      else
        render action: 'edit'
      end
    rescue RSolr::Error::Http => error
      flash[:error] = error.message
      logger.error "GenericFilesController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    def versions
      @version_list = version_list
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      # attrs_without_visibility_info = actor.interpret_visibility(attributes)
      file_attributes = CurationConcerns::Forms::GenericFileEditForm.model_attributes(attributes)
      actor.update_metadata(file_attributes, attributes)
    end

    protected

      def version_list
        CurationConcerns::VersionListPresenter.new(@generic_file.original_file.versions.all)
      end

      def wants_to_revert?
        params.key?(:revision) && params[:revision] != @generic_file.latest_content_version.label
      end

      def actor
        @actor ||= ::CurationConcerns::GenericFileActor.new(@generic_file, current_user)
      end

      def attributes
        # params.fetch(:generic_file, {}).dup  # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
        params.fetch(:generic_file, {}).except(:files).permit!.dup # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
      end

      def json_error(error, name = nil, additional_arguments = {})
        args = { error: error }
        args[:name] = name if name
        render additional_arguments.merge(json: [args])
      end

      def _prefixes
        # This allows us to use the unauthorized and form_permission template in curation_concerns/base
        @_prefixes ||= super + ['curation_concerns/base']
      end

      def empty_file?(file)
        (file.respond_to?(:tempfile) && file.tempfile.size == 0) || (file.respond_to?(:size) && file.size == 0)
      end

      def process_file(file)
        update_metadata_from_upload_screen
        actor.create_metadata(params[:upload_set_id], parent_id, params[:generic_file])
        if actor.create_content(file)
          respond_to do |format|
            format.html do
              if request.xhr?
                render 'jq_upload', formats: 'json', content_type: 'text/html'
              else
                redirect_to [main_app, :curation_concerns, @generic_file.generic_works.first]
              end
            end
            format.json do
              render 'jq_upload'
            end
          end
        else
          msg = @generic_file.errors.full_messages.join(', ')
          flash[:error] = msg
          json_error "Error creating generic file: #{msg}"
        end
      end

      # this is provided so that implementing application can override this behavior and map params to different attributes
      def update_metadata_from_upload_screen
        # Relative path is set by the jquery uploader when uploading a directory
        @generic_file.relative_path = params[:relative_path] if params[:relative_path]
      end
  end
end
