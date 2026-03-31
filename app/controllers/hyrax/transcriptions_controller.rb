# frozen_string_literal: true

module Hyrax
  class TranscriptionsController < ApplicationController
    def show
      file_metadata = Hyrax.query_service.find_by(id: params[:id])
      file_object = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
      transcription = file_object.read

      response.headers['Access-Control-Allow-Origin'] = '*'
      send_data transcription, type: 'text/vtt; charset=utf-8', disposition: 'inline'
    end
  end
end