# frozen_string_literal: true

# Moves one file set's original file from disk to S3. Unexpected errors are raised so the job retries;
# verification failures (suspect, mismatch, ...) are logged and left on disk.
class MigrateFileSetToS3Job < Hyrax::ApplicationJob
  queue_as { ENV.fetch('S3_MIGRATION_QUEUE', 'default') }
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(file_set_id, dry_run: false)
    file_set = Hyrax.query_service.find_by(id: file_set_id)
    original = Hyrax.custom_queries.find_original_file(file_set:)
    return unless original

    result = Hyrax::S3Migration::FileMigrator.new(file_set:, original:, dry_run:).call
    Rails.logger.info("[S3Migration] #{file_set_id} #{result.status} #{result.message}".strip)
    result
  rescue Valkyrie::Persistence::ObjectNotFoundError
    Rails.logger.info("[S3Migration] #{file_set_id} not found; skipping")
  end
end
