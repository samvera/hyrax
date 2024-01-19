# frozen_string_literal: true
module Hyrax
  # Overrides Hydra::Controller:DownloadBehavior handing of HEAD requests to
  # respond with same headers as a GET request would receive.
  module StreamFileDownloadsControllerBehavior
    protected

    # Handle the HTTP show request
    def send_content
      response.headers['Accept-Ranges'] = 'bytes'
      if request.headers['HTTP_RANGE']
        send_range
      else
        send_file_contents
      end
    end

    # rubocop:disable Metrics/AbcSize
    def send_range
      _, range = request.headers['HTTP_RANGE'].split('bytes=')
      from, to = range.split('-').map(&:to_i)
      to = file.size - 1 unless to
      length = to - from + 1
      response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
      response.headers['Content-Length'] = length.to_s
      self.status = 206
      prepare_file_headers

      if request.head?
        head status
      else
        stream_body file.stream(request.headers['HTTP_RANGE'])
      end
    end
    # rubocop:enable Metrics/AbcSize

    def send_file_contents
      return unless stale?(last_modified: file_last_modified, template: false)

      self.status = 200
      prepare_file_headers

      if request.head?
        head status
      else
        stream_body file.stream
      end
    end

    def file_last_modified
      file.modified_date
    end
  end
end
