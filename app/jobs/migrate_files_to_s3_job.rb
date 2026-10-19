# frozen_string_literal: true

# Enqueues a MigrateFileSetToS3Job for every file set whose original is still on disk.
class MigrateFilesToS3Job < Hyrax::ApplicationJob
  queue_as { ENV.fetch('S3_MIGRATION_QUEUE', 'default') }

  def perform(limit: nil)
    enqueued = 0
    Hyrax::S3Migration.each_file_set do |file_set|
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
    on_error = ->(fs, error) { Rails.logger.warn("[S3Migration] #{fs.id} has no readable original: #{error.class}") }
    Hyrax::S3Migration.original_for(file_set, on_error:)&.file_identifier.to_s.start_with?('disk://')
  end
end
