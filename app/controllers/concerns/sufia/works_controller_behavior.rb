module Sufia
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs
    include CurationConcerns::CurationConcernController

    included do
      self.show_presenter = Sufia::WorkShowPresenter
    end

    module ClassMethods
      # We don't want the actions to occur until after the concern has been loaded and authorized
      # @note this is a terribly side-effecty kludge
      def curation_concern_type=(curation_concern_type)
        super
        before_action :build_breadcrumbs, only: [:edit, :show]
        before_action :save_permissions, only: :update
      end
    end

    def new
      # TODO: move these lines to the work form builder in Hyrax
      curation_concern.depositor = current_user.user_key

      # admin_set_id is required on the client, otherwise simple_form renders a blank option.
      # however it isn't a required field for someone to submit via json.
      # Set the first admin_set they have access to.
      admin_set = Sufia::AdminSetService.new(self).search_results(:deposit).first
      curation_concern.admin_set_id = admin_set && admin_set.id
      super
    end

    protected

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
            flash[:notice] = t('sufia.works.create.after_create_html', application_name: view_context.application_name)
            redirect_to [main_app, curation_concern]
          end
          wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
        end
      end

      def after_update_response
        if permissions_changed? && curation_concern.file_sets.present?
          redirect_to sufia.confirm_access_curation_concerns_permission_path(curation_concern)
        else
          super
        end
      end

      def after_destroy_response(title)
        respond_to do |wants|
          wants.html { redirect_to sufia.dashboard_works_path, notice: "Deleted #{title}" }
          wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
        end
      end

      # Called by CurationConcerns::CurationConcernController#show
      def additional_response_formats(format)
        format.endnote do
          send_data(presenter.solr_document.export_as_endnote,
                    type: "application/x-endnote-refer",
                    filename: presenter.solr_document.endnote_filename)
        end
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('sufia.dashboard.my.works'), sufia.dashboard_works_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'edit'.freeze
          add_breadcrumb curation_concern.to_s, main_app.polymorphic_path(curation_concern)
          add_breadcrumb t('sufia.works.edit.breadcrumb'), request.path
        when 'show'.freeze
          add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
        end
      end

      def save_permissions
        @saved_permissions = curation_concern.permissions.map(&:to_hash)
      end

      def permissions_changed?
        @saved_permissions != curation_concern.permissions.map(&:to_hash)
      end
  end
end
