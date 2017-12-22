class CreateDerivativesJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    return if file_set.video? && !Hyrax.config.enable_ffmpeg
    pathname = Hyrax::WorkingDirectory.find_or_retrieve(file_id, file_set.id, filepath)
    file_set.create_derivatives(pathname)

    # Reload from Fedora and reindex for thumbnail and extracted text
    reloaded = Hyrax::Queries.find_by(id: file_set.id)
    solr_persister = Valkyrie::MetadataAdapter.find(:index_solr).persister
    solr_persister.save(resource: reloaded)
    solr_persister.save(resource: reloaded.parent) if parent_needs_reindex?(reloaded)
  end

  # If this file_set is the thumbnail for the parent work,
  # then the parent also needs to be reindexed.
  def parent_needs_reindex?(file_set)
    return false unless file_set.parent
    file_set.parent.thumbnail_id == file_set.id
  end
end
