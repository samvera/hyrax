module Sufia
  module FileSetsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      # prepend this hook so that it comes before load_and_authorize
      prepend_before_action :authenticate_user!, except: [:show, :citation, :stats]
      before_action :build_breadcrumbs, only: [:show, :edit, :stats]

      self.show_presenter = Sufia::FileSetPresenter
      self.form_class = Sufia::Forms::FileSetEditForm
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
        add_breadcrumb presenter.parent.to_s, main_app.polymorphic_path(presenter.parent)
        add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
      end
    end

    # This allows us to use the templates in curation_concerns/file_sets
    def self.local_prefixes
      ['curation_concerns/file_sets']
    end

    protected

      def initialize_edit_form
        @version_list = version_list
        super
      end

      def version_list
        original = @file_set.original_file
        versions = original ? original.versions.all : []
        CurationConcerns::VersionListPresenter.new(versions)
      end

      def actor
        @actor ||= CurationConcerns::Actors::FileSetActor.new(@file_set, current_user)
      end
  end
end
