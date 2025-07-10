# frozen_string_literal: true
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile

    def create
      if params[:id].blank?
        @upload.attributes = { file: params[:files].first,
                               user: current_user }
      else
        upload_with_chunking
      end
      @upload.save!
    end

    def destroy
      @upload.destroy
      head :no_content
    end

    private

    def upload_with_chunking
      @upload = Hyrax::UploadedFile.find(params[:id])
      unpersisted_upload = Hyrax::UploadedFile.new(file: params[:files].first, user: current_user)
      content_range = request.headers['CONTENT-RANGE']

      if content_range
        handle_chunk(content_range, unpersisted_upload.file)
      else
        @upload.file = unpersisted_upload.file
      end
    end

    def handle_chunk(content_range, chunk)
      file_path = @upload.file.path

      current_size = 0
      if file_path && File.exist?(file_path)
        File.open(file_path, "r") { |f| current_size = f.size }
      end

      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i

      if @upload.file.present? && begin_of_chunk == current_size
        `sync #{file_path}`
        File.open(file_path, "ab") { |f| f.write(chunk.read) }
        `sync #{file_path}`
      else
        @upload.file = chunk
      end
    end
  end
end
