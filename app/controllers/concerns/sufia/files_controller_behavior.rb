module Sufia
  module FilesController
    extend ActiveSupport::Autoload
    autoload :BrowseEverything
    autoload :LocalIngestBehavior
    autoload :UploadCompleteBehavior
  end
  module FilesControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      include Blacklight::Configurable
      include Sufia::FilesController::BrowseEverything
      include Sufia::FilesController::LocalIngestBehavior
      extend Sufia::FilesController::UploadCompleteBehavior

      layout "sufia-one-column"

      copy_blacklight_config_from(CatalogController)

      # actions: index, create, new, edit, show, update,
      #          destroy, permissions, citation, stats

      # prepend this hook so that it comes before load_and_authorize
      prepend_before_action :authenticate_user!, except: [:show, :citation, :stats]
      before_action :build_breadcrumbs, only: [:show, :edit, :stats]
    end

    def new
      @upload_set_id = ActiveFedora::Noid::Service.new.mint
    end

    # routed to /files/:id/stats
    def stats
      @stats = FileUsage.new(params[:id])
    end

    # routed to /files/:id/citation
    def citation
    end

    # Called by CurationConcerns::FileSetsControllerBehavior#show
    def additional_response_formats(format)
      format.endnote { render text: presenter.solr_document.export_as_endnote }
    end

    protected

      def _prefixes
        # This allows us to use the templates in curation_concerns/file_sets
        @_prefixes ||= ['curation_concerns/file_sets'] + super
      end

      def initialize_edit_form
        @version_list = version_list
        super
      end

      def version_list
        original = @file_set.original_file
        versions = original ? original.versions.all : []
        CurationConcerns::VersionListPresenter.new(versions)
      end

      def process_file(file)
        if terms_accepted?
          super(file)
        else
          json_error "You must accept the terms of service!", file.original_filename
        end
      end

      # override this method if you want to change how the terms are accepted on upload.
      def terms_accepted?
        params[:terms_of_service] == '1'
      end

      # called by CurationConcerns::FileSetsControllerBehavior#process_file
      def update_metadata_from_upload_screen
        @file_set.on_behalf_of = params[:on_behalf_of] if params[:on_behalf_of]
        super
      end

      def show_presenter
        Sufia::FileSetPresenter
      end

      # overrides the same method provided by CurationConcerns::FileSetsControllerBehavior in order to inject Sufia's FileSetEditForm
      def form_class
        Sufia::Forms::FileSetEditForm
      end
  end
end
