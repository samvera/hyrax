module Sufia
  module FileSetsController::UploadCompleteBehavior
    def upload_complete_path(upload_set_id)
      Rails.application.routes.url_helpers.edit_upload_set_path(upload_set_id)
    end

    def destroy_complete_path(_params)
      Sufia::Engine.routes.url_helpers.dashboard_files_path
    end
  end
end
