module Sufia
  module FilesController::UploadCompleteBehavior
    def upload_complete_path(upload_set_id)
      Sufia::Engine.routes.url_helpers.batch_edit_path(upload_set_id)
    end

    def destroy_complete_path(_params)
      Sufia::Engine.routes.url_helpers.dashboard_files_path
    end
  end # /FilesController::UploadCompleteBehavior
end # /Sufia
