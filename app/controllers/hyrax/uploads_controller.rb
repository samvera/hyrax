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

      # Check if CONTENT-RANGE header is present
      content_range = request.headers['CONTENT-RANGE']
      return @upload.file = unpersisted_upload.file if content_range.nil?

      # deal with chunks
      current_size = @upload.file.size
      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i # "bytes 100-999999/1973660678" will return '100'

      # Add the following chunk to the incomplete upload
      if @upload.file.present? && begin_of_chunk == current_size
        File.open(@upload.file.path, "ab") { |f| f.write(params[:files].first.read) }
      else
        @upload.file = unpersisted_upload.file
      end
    end
  end
end
