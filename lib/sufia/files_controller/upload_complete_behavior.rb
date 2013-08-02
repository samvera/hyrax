module Sufia
  module FilesController::UploadCompleteBehavior
    def upload_complete_path(batch_id)
      Sufia::Engine.routes.url_helpers.batch_edit_path(batch_id)
    end
  end # /FilesController::UploadCompleteBehavior
end # /Sufia