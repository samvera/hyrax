# frozen_string_literal: true
class ValkyrieCharacterizationJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  def perform(file_metadata_id)
    file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file_metadata_id)
    Hyrax.config.characterization_service
         .run(metadata: file_metadata, file: file_metadata.file, **Hyrax.config.characterization_options)
  end
end
