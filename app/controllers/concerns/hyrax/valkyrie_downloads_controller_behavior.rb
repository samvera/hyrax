# frozen_string_literal: true
module Hyrax
  module ValkyrieDownloadsControllerBehavior
    def show_valkyrie
      file_set_id = params.require(:id)
      file_set = Hyrax.query_service.find_by(id: file_set_id)
      send_file_contents_valkyrie(file_set)
    end

    private

    def send_file_contents_valkyrie(file_set)
      response.headers["Accept-Ranges"] = "bytes"
      self.status = 200
      use = params.fetch(:file, :original_file).to_sym
      file_metadata = find_file_metadata(file_set: file_set, use: use)
      return unless stale?(last_modified: file_metadata.updated_at, template: false)

      file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
      prepare_file_headers_valkyrie(metadata: file_metadata, file: file)

      # Warning - using the range header will load the range selection in to memory
      # this can cause memory bloat
      if request.headers['Range']
        file.rewind
        send_data send_range_valkyrie(file: file), data_options(file_metadata)
      else
        send_file file.disk_path, data_options(file_metadata).except(:status)
      end
    end

    def data_options(file_metadata)
      {
        type: file_metadata.mime_type,
        filename: file_metadata.original_filename,
        disposition: "inline",
        status: status
      }
    end

    def send_range_valkyrie(file:)
      _, range = request.headers['Range'].split('bytes=')
      from, to = range.split('-').map(&:to_i)
      to = file.size - 1 unless to
      length = to - from + 1
      response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
      response.headers['Content-Length'] = length.to_s
      self.status = 206
      file.read from # Seek to start of requested range
      file.read length
    end

    def prepare_file_headers_valkyrie(metadata:, file:, inline: false)
      inline_display = ActiveRecord::Type::Boolean.new.cast(params.fetch(:inline, inline))
      response.headers["Content-Disposition"] = "#{inline_display ? 'inline' : 'attachment'}; filename=#{metadata.original_filename}"
      response.headers["Content-Type"] = metadata.mime_type
      response.headers["Content-Length"] ||= (file.try(:size) || metadata.size.first).to_s
      # Prevent Rack::ETag from calculating a digest over body
      response.headers["Last-Modified"] = metadata.updated_at.utc.strftime("%a, %d %b %Y %T GMT")
      self.content_type = metadata.mime_type
    end

    def find_file_metadata(file_set:, use: :original_file)
      use = :thumbnail_file if use == :thumbnail
      begin
        use = Hyrax::FileMetadata::Use.uri_for(use: use)
      rescue ArgumentError
        raise Hyrax::ObjectNotFoundError
      end
      results = Hyrax.custom_queries.find_many_file_metadata_by_use(resource: file_set, use: use)
      results.first || raise(Hyrax::ObjectNotFoundError)
    end
  end
end
