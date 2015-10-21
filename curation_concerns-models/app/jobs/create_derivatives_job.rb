class CreateDerivativesJob < ActiveFedoraIdBasedJob
  queue_as :derivatives

  def perform(id, file_name)
    @id = id
    return if file_set.video? && !CurationConcerns.config.enable_ffmpeg

    file_set.create_derivatives(file_name)
    # The thumbnail is indexed in the solr document, so reindex
    file_set.update_index
    file_set.parent.update_index if parent_needs_reindex?
  end

  # If this file_set is the thumbnail for the parent work,
  # then the parent also needs to be reindexed.
  def parent_needs_reindex?
    return false unless file_set.parent
    file_set.parent.thumbnail_id == file_set.id
  end
end
