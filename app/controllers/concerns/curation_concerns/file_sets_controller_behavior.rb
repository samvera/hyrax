module CurationConcerns
  module FileSetsControllerBehavior
    extend ActiveSupport::Concern

    included do
      include CurationConcerns::ThemedLayoutController
      with_themed_layout '1_column'
      load_and_authorize_resource class: ::FileSet, except: :show
      helper_method :curation_concern
      include CurationConcerns::ParentContainer
      include Blacklight::Base
      include Blacklight::AccessControls::Catalog
      copy_blacklight_config_from(::CatalogController)
    end

    def curation_concern
      @file_set
    end

    # routed to /files/new
    def new
    end

    # routed to /files/:id/edit
    def edit
      initialize_edit_form
    end

    # routed to /files (POST)
    def create
      create_from_upload(params)
    end

    def create_from_upload(params)
      # check error condition No files
      return render_json_response(response_type: :bad_request, options: { message: 'Error! No file to save' }) unless params.key?(:file_set) && params.fetch(:file_set).key?(:files)

      file = params[:file_set][:files].detect { |f| f.respond_to?(:original_filename) }
      if !file
        render_json_response(response_type: :bad_request, options: { message: 'Error! No file for upload', description: 'unknown file' })
      elsif empty_file?(file)
        render_json_response(response_type: :unprocessable_entity, options: { errors: { files: "#{file.original_filename} has no content! (Zero length file)" }, description: t('curation_concerns.api.unprocessable_entity.empty_file') })
      else
        process_file(file)
      end
    rescue RSolr::Error::Http => error
      logger.error "FileSetController::create rescued #{error.class}\n\t#{error}\n #{error.backtrace.join("\n")}\n\n"
      render_json_response(response_type: :internal_error, options: { message: 'Error occurred while creating a FileSet.' })
    ensure
      # remove the tempfile (only if it is a temp file)
      file.tempfile.delete if file.respond_to?(:tempfile)
    end

    # routed to /files/:id
    def show
      respond_to do |wants|
        wants.html { presenter }
        wants.json do
          # load and authorize @curation_concern manually because it's skipped for html
          @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
          authorize! :show, @file_set
          render :show, status: :ok
        end
        additional_response_formats(wants)
      end
    end

    # Gives the class of the show presenter. Override this if you want
    # to use a different presenter.
    def show_presenter
      CurationConcerns::FileSetPresenter
    end

    # Gives the class of the form. Override this if you want
    # to use a different form.
    def form_class
      CurationConcerns::Forms::FileSetEditForm
    end

    def destroy
      parent = @file_set.in_works.first
      actor.destroy
      redirect_to [main_app, parent], notice: 'The file has been deleted.'
    end

    # routed to /files/:id (PUT)
    def update
      success = if wants_to_revert?
                  actor.revert_content(params[:revision])
                elsif params.key?(:file_set)
                  if params[:file_set].key?(:files)
                    actor.update_content(params[:file_set][:files].first)
                  else
                    update_metadata
                  end
                end
      if success
        after_update_response
      else
        respond_to do |wants|
          wants.html do
            initialize_edit_form
            render 'edit', status: :unprocessable_entity
          end
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: @file_set.errors }) }
        end
      end
    rescue RSolr::Error::Http => error
      flash[:error] = error.message
      logger.error "FileSetsController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    def after_update_response
      respond_to do |wants|
        wants.html do
          redirect_to [main_app, @file_set], notice: "The file #{view_context.link_to(@file_set, [main_app, @file_set])} has been updated."
        end
        wants.json { render :show, status: :ok, location: polymorphic_path([main_app, @file_set]) }
      end
    end

    def versions
      @version_list = version_list
    end

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      file_attributes = form_class.model_attributes(attributes)
      actor.update_metadata(file_attributes)
    end

    protected

      def presenter
        @presenter ||= begin
          _, document_list = search_results(params, [:add_access_controls_to_solr_params, :find_one, :only_file_sets])
          curation_concern = document_list.first
          raise CanCan::AccessDenied unless curation_concern
          show_presenter.new(curation_concern, current_ability)
        end
      end

      def initialize_edit_form
        @groups = current_user.groups
      end

      # Override this method to add additional response
      # formats to your local app
      def additional_response_formats(_)
        # nop
      end

      def file_set_params
        params.require(:file_set).permit(
          :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo, :visibility_during_lease, :lease_expiration_date, :visibility_after_lease, :visibility, title: [])
      end

      def version_list
        CurationConcerns::VersionListPresenter.new(@file_set.original_file.versions.all)
      end

      def wants_to_revert?
        params.key?(:revision) && params[:revision] != @file_set.latest_content_version.label
      end

      def actor
        @actor ||= ::CurationConcerns::FileSetActor.new(@file_set, current_user)
      end

      def attributes
        # params.fetch(:file_set, {}).dup  # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
        params.fetch(:file_set, {}).except(:files).permit!.dup # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
      end

      def _prefixes
        # This allows us to use the unauthorized and form_permission template in curation_concerns/base
        @_prefixes ||= super + ['curation_concerns/base']
      end

      def json_error(error, name = nil, additional_arguments = {})
        args = { error: error }
        args[:name] = name if name
        render additional_arguments.merge(json: [args])
      end

      def empty_file?(file)
        (file.respond_to?(:tempfile) && file.tempfile.size == 0) || (file.respond_to?(:size) && file.size == 0)
      end

      def process_file(file)
        update_metadata_from_upload_screen
        actor.create_metadata(find_parent_by_id, params[:file_set])
        if actor.create_content(file)
          respond_to do |format|
            format.html do
              if request.xhr?
                render 'jq_upload', formats: 'json', content_type: 'text/html'
              else
                redirect_to [main_app, @file_set.in_works.first]
              end
            end
            format.json do
              render 'jq_upload', status: :created, location: polymorphic_path([main_app, curation_concern])
            end
          end
        else
          msg = @file_set.errors.full_messages.join(', ')
          flash[:error] = msg
          json_error "Error creating generic file: #{msg}"
        end
      end

      # this is provided so that implementing application can override this behavior and map params to different attributes
      def update_metadata_from_upload_screen
        # Relative path is set by the jquery uploader when uploading a directory
        @file_set.relative_path = params[:relative_path] if params[:relative_path]
      end

      def curation_concern_type
        ::FileSet
      end
  end
end
