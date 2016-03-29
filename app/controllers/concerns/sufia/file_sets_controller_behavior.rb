module Sufia
  module FileSetsController
    extend ActiveSupport::Autoload
    autoload :BrowseEverything
    autoload :LocalIngestBehavior
    autoload :UploadCompleteBehavior
  end
  module FileSetsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      include Blacklight::Configurable
      include Sufia::FileSetsController::BrowseEverything
      include Sufia::FileSetsController::LocalIngestBehavior
      extend Sufia::FileSetsController::UploadCompleteBehavior

      layout "sufia-one-column"

      copy_blacklight_config_from(CatalogController)

      # actions: index, create, new, edit, show, update,
      #          destroy, permissions, citation, stats

      # prepend this hook so that it comes before load_and_authorize
      prepend_before_action :authenticate_user!, except: [:show, :citation, :stats]
      before_action :build_breadcrumbs, only: [:show, :edit, :stats]
    end

    def new
      @upload_set_id = SecureRandom.uuid
    end

    # routed to /files/:id/stats
    def stats
      @stats = FileUsage.new(params[:id])
    end

    # routed to /files/:id/citation
    def citation
    end

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('sufia.dashboard.my.works'), sufia.dashboard_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'edit'.freeze
        add_breadcrumb I18n.t("sufia.file_set.browse_view"), main_app.curation_concerns_file_set_path(params["id"])
      when 'show'.freeze
        add_breadcrumb presenter.parent.title, sufia.polymorphic_path(presenter.parent)
        add_breadcrumb presenter.title, main_app.polymorphic_path(presenter)
      end
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

      def show_presenter
        Sufia::FileSetPresenter
      end

      # overrides the same method provided by CurationConcerns::FileSetsControllerBehavior in order to inject Sufia's FileSetEditForm
      def form_class
        Sufia::Forms::FileSetEditForm
      end

      # overrides Curation Concerns method
      def file_set_params
        return {} if params[:file_set].blank?
        super
      end

      def find_parent_by_id
        return default_work_from_params unless parent_id.present?
        super
      end

      # If the user is creating a bunch of files, and not in a work context,
      # create a work for each file.
      def default_work_from_params
        title = params[:file_set][:files].first.original_filename
        DefaultWorkService.create(params[:upload_set_id], title, current_user)
      end

      def actor
        @actor ||= CurationConcerns::FileSetActor.new(@file_set, current_user)
      end
  end
end
