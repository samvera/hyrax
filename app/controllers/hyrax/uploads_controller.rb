# frozen_string_literal: true
module Hyrax
  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile
    before_action :enforce_upload_limit!, only: [:create]

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

    def enforce_upload_limit!
      limit = upload_limit
      return if limit.blank?

      incoming = params[:files]&.first
      return unless incoming.respond_to?(:original_filename)

      return if assembled_size(incoming) <= limit

      render json: {
        files: [{
          name: incoming.original_filename,
          error: "File exceeds the #{ActiveSupport::NumberHelper.number_to_human_size(limit)} upload limit."
        }]
      }, status: :payload_too_large
    end

    def upload_limit
      raw = Hyrax.config.uploader[:maxFileSize]
      return nil if raw.blank?

      limit = raw.to_i
      limit.positive? ? limit : nil
    end

    def assembled_size(incoming)
      content_range = request.headers['CONTENT-RANGE']
      return incoming.size if params[:id].blank? || content_range.blank?

      current = bytes_already_uploaded
      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i

      begin_of_chunk == current ? current + incoming.size : incoming.size
    end

    def bytes_already_uploaded
      path = Hyrax::UploadedFile.find_by(id: params[:id])&.file&.path
      return 0 if path.blank? || !File.exist?(path)

      File.size(path)
    end

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
