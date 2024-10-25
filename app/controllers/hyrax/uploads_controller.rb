# frozen_string_literal: true
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile

    def create
      if params[:id].blank?
        handle_new_upload
      else
        handle_chunked_upload
      end
      @upload.save!
    end

    def destroy
      @upload.destroy
      head :no_content
    end

    private

    def handle_new_upload
      @upload.attributes = { file: params[:files].first, user: current_user }
    end

    def handle_chunked_upload
      @upload = Hyrax::UploadedFile.find(params[:id])
      unpersisted_upload = Hyrax::UploadedFile.new(file: params[:files].first, user: current_user)

      if chunk_valid?(@upload)
        append_chunk(@upload)
      else
        replace_file(@upload, unpersisted_upload)
      end
    end

    def chunk_valid?(upload)
      current_size = upload.file.size
      content_range = request.headers['CONTENT-RANGE']

      return false unless content_range

      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i
      upload.file.present? && begin_of_chunk == current_size
    end

    def append_chunk(upload)
      File.open(upload.file.path, "ab") { |f| f.write(params[:files].first.read) }
    end

    def replace_file(upload, unpersisted_upload)
      upload.file = unpersisted_upload.file
      upload.save!
      upload.reload
    end
  end
end
