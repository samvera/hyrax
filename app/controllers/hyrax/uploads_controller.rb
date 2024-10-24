# frozen_string_literal: true
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile, except: :resume_upload

    def create
      @upload.attributes = { file: params[:files].first,
                             user: current_user }
      @upload.save!
    end

    def destroy
      @upload.destroy
      head :no_content
    end

    def resume_upload
      file_name = params[:file]
      uploaded_file = Hyrax::UploadedFile.find_by(file: file_name)
      
      if uploaded_file
        render json: { file: { name: uploaded_file.file_set_uri, size: uploaded_file.file.size } }
      else
        render json: { file: nil }
      end
    end
  end
end
