# frozen_string_literal: true
module Hyrax
  module LocalFileDownloadsControllerBehavior
    protected

    # Handle the HTTP show request
    def send_local_content
      response.headers['Accept-Ranges'] = 'bytes'
      if request.headers['Range']
        send_range_for_local_file
      else
        send_local_file_contents
      end
    end

    # render an HTTP Range response
    def send_range_for_local_file
      _, range = request.headers['Range'].split('bytes=')
      from, to = range.split('-').map(&:to_i)
      to = local_file_size - 1 unless to
      length = to - from + 1
      response.headers['Content-Range'] = "bytes #{from}-#{to}/#{local_file_size}"
      response.headers['Content-Length'] = length.to_s
      self.status = 206
      prepare_local_file_headers
      # For derivatives stored on the local file system
      if request.head?
        head status
      else
        send_data IO.binread(file, length, from), local_derivative_download_options.merge(status: status)
      end
    end

    def send_local_file_contents
      return unless stale?(last_modified: local_file_last_modified, template: false)
      self.status = 200
      prepare_local_file_headers
      # For derivatives stored on the local file system
      if request.head?
        head status
      else
        send_file file, local_derivative_download_options
      end
    end

    def local_file_size
      File.size(file)
    end

    def local_file_mime_type
      mime_type_for(file)
    end

    # @return [String] the filename
    def local_file_name
      params[:filename] || File.basename(file) || (asset.respond_to?(:label) && asset.label)
    end

    def local_file_last_modified
      File.mtime(file) if file.is_a? String
    end

    # Override
    def prepare_local_file_headers
      send_file_headers! local_derivative_download_options
      response.headers['Content-Type'] = local_file_mime_type
      response.headers['Content-Length'] ||= local_file_size.to_s
      # Prevent Rack::ETag from calculating a digest over body
      response.headers['Last-Modified'] = local_file_last_modified.httpdate
      self.content_type = local_file_mime_type
    end

    private

    # Override this method if you want to change the options sent when downloading
    # a derivative file
    def local_derivative_download_options
      { type: local_file_mime_type, filename: local_file_name, disposition: 'inline' }
    end
  end
end
