module Sufia
  module FileSetsController::LocalIngestBehavior
    include ActiveSupport::Concern

    def create
      file_set_attributes = params.fetch(:file_set)
      if file_set_attributes[:local_file].present?
        upload_set_id = params.fetch(:upload_set_id)
        perform_local_ingest(file_set_attributes, params.fetch(:parent_id), upload_set_id)
      else
        super
      end
    end

    private

      def perform_local_ingest(file_set_attributes, parent_id, upload_set_id)
        if Sufia.config.enable_local_ingest && current_user.respond_to?(:directory)
          local_files = file_set_attributes.fetch(:local_file)
          service = IngestLocalFileService.new(current_user, logger)
          if service.ingest_local_file(local_files, parent_id)
            redirect_to CurationConcerns::FileSetsController.upload_complete_path(upload_set_id)
          else
            flash[:alert] = "Error importing files from user directory."
            render :new
          end
        else
          flash[:alert] = "Your account is not configured for importing files from a user-directory on the server."
          render :new
        end
      end
  end # /FileSetsController::LocalIngestBehavior
end # /Sufia
