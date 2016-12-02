module Sufia
  module WorksControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::CurationConcernController

    def new
      curation_concern.depositor = current_user.user_key
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
            flash[:notice] = t('sufia.works.new.after_create_html', application_name: view_context.application_name)
            redirect_to [main_app, curation_concern]
          end
          wants.json { render :show, status: :created, location: polymorphic_path([main_app, curation_concern]) }
        end
      end

      def after_update_response
        if permissions_changed? && curation_concern.file_sets.present?
          redirect_to sufia.confirm_access_permission_path(curation_concern)
        elsif curation_concern.visibility_changed? && curation_concern.file_sets.present?
          redirect_to sufia.confirm_permission_path(curation_concern)
        else
          respond_to do |wants|
            wants.html { redirect_to [main_app, curation_concern] }
            wants.json { render :show, status: :ok, location: polymorphic_path([main_app, curation_concern]) }
          end
        end
      end

      # Called by Sufia::CurationConcernController#show
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
