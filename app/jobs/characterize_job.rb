class CharacterizeJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  delegate :query_service, to: :metadata_adapter

  # @param [String] id of the FileSet to characterize
  def perform(file_set_id)
    file_set = query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    metadata_adapter.persister.buffer_into_index do |buffered_adapter|
      Valkyrie::FileCharacterizationService.for(file_node: file_set, persister: buffered_adapter.persister).characterize
    end
    # TODO: derivatives
    # CreateDerivativesJob.perform_later(file_set, file_id, filepath)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
end
