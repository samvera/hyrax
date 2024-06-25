# frozen_string_literal: true
module Hyrax
  module ValkyrieDownloadsControllerBehavior
    def show_valkyrie
      file_set_id = params.require(:id)
      file_set = Hyrax.query_service.find_by(id: file_set_id)
      send_file_contents_valkyrie(file_set)
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def send_file_contents_valkyrie(file_set)
      # TODO: Refactor for goddess adapter usage
      # This determines if we're dealing with active fedora or not. If we are,
      # fallback to the original implementation.
      mime_type = params[:mime_type]
      file_metadata = find_file_metadata(file_set: file_set, use: use, mime_type: mime_type)
      begin
        ::Valkyrie::StorageAdapter.adapter_for(id: file_metadata.file_identifier)
      rescue Valkyrie::StorageAdapter::AdapterNotFoundError
        return show_active_fedora
      end

      response.headers["Accept-Ranges"] = "bytes"
      self.status = 200
      return unless stale?(last_modified: file_metadata.updated_at, template: false)

      file = Valkyrie::StorageAdapter.find_by(id: file_metadata.file_identifier)
      prepare_file_headers_valkyrie(metadata: file_metadata, file: file)

      # Warning - using the range header will load the range selection in to memory
      # this can cause memory bloat
      if request.headers['Range']
        if request.head?
          prepare_range_headers_valkyrie(file: file)
          head status
        else
          send_data send_range_valkyrie(file: file), data_options(file_metadata)
        end
      elsif request.head?
        head status
      else
        send_file file.disk_path, data_options(file_metadata).except(:status)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def data_options(file_metadata)
      {
        type: file_metadata.mime_type,
        filename: file_metadata.original_filename,
        disposition: disposition,
        status: status
      }
    end

    def use
      params.fetch(:file, :original_file).to_sym
    end

    def disposition
      if ActiveRecord::Type::Boolean.new.cast(params.fetch(:inline, use != :original_file))
        'inline'
      else
        'attachment'
      end
    end

    def send_range_valkyrie(file:)
      from, length = prepare_range_headers_valkyrie(file: file)
      file.rewind
      file.read from # Seek to start of requested range
      file.read length
    end

    def prepare_range_headers_valkyrie(file:)
      _, range = request.headers['Range'].split('bytes=')
      from, to = range.split('-').map(&:to_i)
      to = file.size - 1 unless to
      length = to - from + 1
      response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
      response.headers['Content-Length'] = length.to_s
      self.status = 206
      [from, length]
    end

    # rubocop:disable Metrics/AbcSize
    def prepare_file_headers_valkyrie(metadata:, file:)
      response.headers["Content-Disposition"] =
        ActionDispatch::Http::ContentDisposition.format(disposition: disposition, filename: metadata.original_filename)
      response.headers["Content-Type"] = metadata.mime_type
      response.headers["Content-Length"] ||= (file.try(:size) || metadata.size.first).to_s
      headers["Content-Transfer-Encoding"] = "binary"
      # Prevent Rack::ETag from calculating a digest over body
      response.headers["Last-Modified"] = metadata.updated_at.utc.strftime("%a, %d %b %Y %T GMT")
      self.content_type = metadata.mime_type
      response.cache_control[:public] ||= false
    end
    # rubocop:enable Metrics/AbcSize

    def find_file_metadata(file_set:, use: :original_file, mime_type: nil)
      if mime_type.nil?
        use = :thumbnail_file if use == :thumbnail
        use = Hyrax::FileMetadata::Use.uri_for(use: use)
        results = Hyrax.custom_queries.find_many_file_metadata_by_use(resource: file_set, use: use)
      else
        files = Hyrax.custom_queries.find_files(file_set: file_set)
        results = [files.find { |f| f.mime_type == mime_type }]
      end

      results.first || raise(Hyrax::ObjectNotFoundError)
    rescue ArgumentError
      raise(Hyrax::ObjectNotFoundError)
    end
  end
end
