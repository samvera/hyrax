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

      # In a multi-pod environment with a shared filesystem (like NFS), attribute
      # caching can cause `File.size` to return a stale value. Opening the file
      # for reading forces a metadata refresh, ensuring we get the correct size
      # without reading the entire file into memory.
      current_size = 0
      File.open(file_path, "r") { |f| current_size = f.size } if file_path && File.exist?(file_path)

      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i

      if @upload.file.present? && begin_of_chunk == current_size
        File.open(file_path, "ab") do |f|
          f.write(chunk.read)
          f.fsync
        end
      else
        @upload.file = chunk
      end
    end
  end
end
