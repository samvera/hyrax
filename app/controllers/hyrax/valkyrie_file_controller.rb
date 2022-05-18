# frozen_string_literal: true
module Hyrax
  class ValkyrieFileController < ApplicationController
    def show
      begin
        metadata = Hyrax.query_service.find_by(id: params[:id])
        file = storage_adapter.find_by(id: metadata.file_identifier)
      rescue => e
        return render plain: e.message, status: :not_found
      end

      send_data file.read
    end

    def storage_adapter
      Hyrax.config.storage_adapter
    end
  end
end
