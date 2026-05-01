# frozen_string_literal: true

module Hyrax
  class TranscriptsController < DownloadsController
    def show
      # Using the extracted text from the index is blocked
      # by https://github.com/samvera/hyrax/issues/7410, so we
      # need to get the original file instead.
      file_metadata = find_file_metadata(file_set: Hyrax.query_service.find_by(id: params.require(:id)))
      file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)

      prepare_file_headers_valkyrie(metadata: file_metadata, file: file)
      response.headers['Access-Control-Allow-Origin'] = '*'
      send_file file.disk_path, data_options(file_metadata)
    end

    private

    def disposition
      'inline'
    end

    def data_options(file_metadata)
      {
        type: "#{file_metadata.mime_type}; charset=utf-8",
        filename: file_metadata.original_filename,
        disposition: disposition
      }
    end
  end
end
