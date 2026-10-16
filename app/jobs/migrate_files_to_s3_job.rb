# frozen_string_literal: true

# Enqueues a MigrateFileSetToS3Job for every file set whose original is still on disk.
class MigrateFilesToS3Job < Hyrax::ApplicationJob
  queue_as { ENV.fetch('S3_MIGRATION_QUEUE', 'default') }

  def perform(limit: nil)
    enqueued = 0
    Hyrax.query_service.find_all_of_model(model: Hyrax::S3Migration.file_set_class).each do |file_set|
      break if limit && enqueued >= limit
      next unless on_disk?(file_set)

      MigrateFileSetToS3Job.perform_later(file_set.id.to_s)
      enqueued += 1
    end
    Rails.logger.info("[S3Migration] enqueued #{enqueued} file sets")
    enqueued
  end

  private

  def on_disk?(file_set)
    Hyrax.custom_queries.find_original_file(file_set:)&.file_identifier.to_s.start_with?('disk://')
  rescue Valkyrie::Persistence::ObjectNotFoundError
    false
  end
end
