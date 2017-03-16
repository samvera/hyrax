module Hyrax
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    # TODO: merge with CurationConcernController
    include Hyrax::CurationConcernController

    def new
      # TODO: move these lines to the work form builder in Hyrax
      curation_concern.depositor = current_user.user_key

      # admin_set_id is required on the client, otherwise simple_form renders a blank option.
      # however it isn't a required field for someone to submit via json.
      # Set the first admin_set they have access to.
      admin_set = Hyrax::AdminSetService.new(self).search_results(:deposit).first
      curation_concern.admin_set_id = admin_set && admin_set.id
      super
    end

    protected

      # Add uploaded_files to the parameters received by the actor.
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
            # Calling `#t` in a controller context does not mark _html keys as html_safe
            flash[:notice] = view_context.t('hyrax.works.create.after_create_html', application_name: view_context.application_name)
            redirect_to [main_app, curation_concern]
          end
          wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
        end
      end

      def after_update_response
        if permissions_changed? && curation_concern.file_sets.present?
          redirect_to hyrax.confirm_access_permission_path(curation_concern)
        else
          super
        end
      end

      def after_destroy_response(title)
        respond_to do |wants|
          wants.html { redirect_to dashboard_works_path, notice: "Deleted #{title}" }
          wants.json { render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") }
        end
      end

      # Called by Hyrax::CurationConcernController#show
      def additional_response_formats(format)
        format.endnote do
          send_data(presenter.solr_document.export_as_endnote,
                    type: "application/x-endnote-refer",
                    filename: presenter.solr_document.endnote_filename)
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
