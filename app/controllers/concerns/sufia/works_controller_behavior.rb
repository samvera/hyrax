module Sufia
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs
    include Sufia::Controller
    include CurationConcerns::CurationConcernController

    included do
      before_action :has_access?, except: :show
      before_action :build_breadcrumbs, only: [:edit, :show]
      self.curation_concern_type = GenericWork
      self.show_presenter = Sufia::WorkShowPresenter
      layout "sufia-one-column"
    end

    def new
      curation_concern.depositor = current_user.user_key
      super
    end

    # Override the default behavior from curation_concerns in order to add uploaded_files to the parameters received by the actor.
    def attributes_for_actor
      attributes = super
      # If they selected a BrowseEverything file, but then clicked the
      # remove button, it will still show up in `selected_files`, but
      # it will no longer be in uploaded_files. By checking the
      # intersection, we get the files they added via BrowseEverything
      # that they have not removed from the upload widget.
      uploaded_files = params.fetch(:uploaded_files, [])
      selected_files = params.fetch(:selected_files, {}).values
      browse_everything_urls = uploaded_files &
                               selected_files.map { |f| f[:url] }

      # we need the hash of files with url and file_name
      browse_everything_files = selected_files
                                .select { |v| uploaded_files.include?(v[:url]) }

      attributes[:remote_files] = browse_everything_files
      # Strip out any BrowseEverthing files from the regular uploads.
      attributes[:uploaded_files] = uploaded_files -
                                    browse_everything_urls
      attributes
    end

    def after_create_response
      respond_to do |wants|
        wants.html do
          flash[:notice] = "Your files are being processed by #{view_context.application_name} in " \
            "the background. The metadata and access controls you specified are being applied. " \
            "Files will be marked <span class=\"label label-danger\" title=\"Private\">Private</span> " \
            "until this process is complete (shouldn't take too long, hang in there!). You may need " \
            "to refresh your dashboard to see these updates."
          redirect_to [main_app, curation_concern]
        end
        wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
      end
    end

    protected

      # Called by CurationConcerns::FileSetsControllerBehavior#show
      def additional_response_formats(format)
        format.endnote { render text: presenter.solr_document.export_as_endnote }
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('sufia.dashboard.my.works'), sufia.dashboard_works_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'edit'.freeze
          add_breadcrumb I18n.t("sufia.work.browse_view"), main_app.curation_concerns_generic_work_path(params["id"])
        when 'show'.freeze
          add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
        end
      end
  end
end
