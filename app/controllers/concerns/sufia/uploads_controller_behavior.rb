module Sufia::UploadsControllerBehavior
  extend ActiveSupport::Concern

  included do
    load_and_authorize_resource class: UploadedFile
  end

  def create
    @upload.attributes = { file: params[:files].first,
                           user: current_user }
    @upload.save!
  end

  def destroy
    @upload.destroy
    head :no_content
  end
end
