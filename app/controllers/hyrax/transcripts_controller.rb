# frozen_string_literal: true

module Hyrax
  class TranscriptsController < ApplicationController
    def show
      file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: params[:id])
      file_object = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)

      # Using .extracted_text is blocked by https://github.com/samvera/hyrax/issues/7410
      transcription = file_object.read

      response.headers['Access-Control-Allow-Origin'] = '*'
      send_data transcription, type: "#{file_metadata.mime_type}; charset=utf-8", disposition: 'inline'
    end
  end
end
