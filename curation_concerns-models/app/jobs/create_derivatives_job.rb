class CreateDerivativesJob < ActiveFedoraIdBasedJob
  queue_as :derivatives

  def perform(id, file_name)
    @id = id
    return if file_set.video? && !CurationConcerns.config.enable_ffmpeg

    file_set.create_derivatives(file_name)
    # The thumbnail is indexed in the solr document, so reindex
    file_set.update_index
  end
end
