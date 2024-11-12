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
    derivative_service.create_derivatives(file.disk_path)
    reindex_parent(file_set_id)
  end

  private

  def reindex_parent(file_set_id)
    file_set = Hyrax.query_service.find_by(id: file_set_id)
    return unless file_set
    parent = Hyrax.custom_queries.find_parent_work(resource: file_set)
    return unless parent&.thumbnail_id == file_set.id
    Hyrax.logger.debug { "Reindexing #{parent.id} due to creation of thumbnail derivatives." }
    Hyrax.index_adapter.save(resource: parent)
  end
end
