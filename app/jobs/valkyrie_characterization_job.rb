# frozen_string_literal: true
class ValkyrieCharacterizationJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # The characterization tool reported a definitive failure (e.g. a file
  # exceeding its configured size limit); retrying won't change the outcome.
  discard_on Hyrax::CharacterizationError do |job, error|
    Hyrax.logger.error("ValkyrieCharacterizationJob discarded for FileMetadata #{job.arguments.first}: #{error.message}")
  end

  def perform(file_metadata_id)
    file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_metadata_id)
    Hyrax.config.characterization_service
         .run(metadata: file_metadata, file: file_metadata.file, **Hyrax.config.characterization_options)
  end
end
