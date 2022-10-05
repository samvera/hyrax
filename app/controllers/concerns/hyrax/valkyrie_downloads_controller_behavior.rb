# frozen_string_literal: true
module Hyrax
  module ValkyrieDownloadsControllerBehavior
    # before_action :authorize_download!

    def show_valkyrie
      file_set_id = params.require(:id)
      file_set = Hyrax.query_service.find_by(id: file_set_id)
      send_file_contents_valkyrie(file_set)
    end

    private

    def send_file_contents_valkyrie(file_set)
      response.headers["Accept-Ranges"] = "bytes"
      self.status = 200
      use = params.fetch(:use, :original_file).to_sym
      file_metadata = find_file_metadata(file_set: file_set, use: use)
      file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
      prepare_file_headers_valkyrie(metadata: file_metadata, file: file)
      file.rewind
      self.response_body = file.read
    end

    def prepare_file_headers_valkyrie(metadata:, file:, inline: false)
      inline_display = ActiveRecord::Type::Boolean.new.cast(params.fetch(:inline, inline))
      response.headers["Content-Disposition"] = "#{inline_display ? 'inline' : 'attachment'}; filename=#{metadata.original_filename}"
      response.headers["Content-Type"] = metadata.mime_type
      response.headers["Content-Length"] ||= (file.try(:size) || metadata.size.first)
      # Prevent Rack::ETag from calculating a digest over body
      response.headers["Last-Modified"] = metadata.updated_at.utc.strftime("%a, %d %b %Y %T GMT")
      self.content_type = metadata.mime_type
    end

    def find_file_metadata(file_set:, use: :original_file)
      use = Hyrax::FileMetadata::Use.uri_for(use: use)

      results = Hyrax.custom_queries.find_many_file_metadata_by_use(resource: file_set, use: use)

      results.first || raise(Hyrax::ObjectNotFoundError)
    end
  end
end
