# frozen_string_literal: true
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile, except: [:resume_upload, :delete_incomplete]

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

    def delete_incomplete
      file_name = params[:file_name]
      uploaded_file = Hyrax::UploadedFile.find_by(file: file_name)

      if uploaded_file
        uploaded_file.destroy
        render json: { success: true, message: "Incomplete upload deleted." }, status: :ok
      else
        render json: { success: false, message: "File not found." }, status: :not_found
      end
    end
  end
end
