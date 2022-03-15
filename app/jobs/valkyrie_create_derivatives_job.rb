# frozen_string_literal: true
class ValkyrieCreateDerivativesJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  def perform(_file_set_id, file_id, _filepath = nil)
    file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_id)
    return if file_metadata.video? && !Hyrax.config.enable_ffmpeg
    # Get file into a local path.
    file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
    # Call derivatives with the file_set.
    derivative_service = Hyrax::DerivativeService.for(file_metadata)
    derivative_service.create_derivatives(file.disk_path)
  end

  private

  def query_service
    Hyrax.query_service
  end

  def storage_adapter
    Hyrax.storage_adapter
  end
end
