module Sufia
  class UploadsController < ApplicationController
    load_and_authorize_resource class: UploadedFile

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
end
