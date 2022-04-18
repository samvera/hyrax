# frozen_string_literal: true
class ValkyrieCreateDerivativesJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  def perform(file_set_id, file_id, _filepath = nil)
    file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_id)
    return if file_metadata.video? && !Hyrax.config.enable_ffmpeg
    # Get file into a local path.
    file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
    # Call derivatives with the file_set.
    derivative_service = Hyrax::DerivativeService.for(file_metadata)

    # Storage adapters that don't use the local disk (like Shrine) won't have a
    # valid #disk_path, so we need to fetch them down first.
    #
    # TODO refactor the derivatives pipeline to not assume a local file path
    diskpath = if File.exist? file.disk_path
                 file.disk_path
               else
                 tmpfile = Tempfile.new(file_set_id, encoding: 'ascii-8bit')
                 tmpfile.write file.read
                 tmpfile
               end

    derivative_service.create_derivatives(diskpath)
    # Trigger a reindex to get the thumbnail path.
    Hyrax.publisher.publish('file.metadata.updated', metadata: file_metadata, user: nil)
  end

  private

  def query_service
    Hyrax.query_service
  end

  def storage_adapter
    Hyrax.storage_adapter
  end
end
