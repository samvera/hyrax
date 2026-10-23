# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Removes an upload the database does not point at, along with the manifest entry that names it.
    class UploadCleanup
      def initialize(file_set:, original:, s3_storage:, manifest:)
        @file_set = file_set
        @original = original
        @s3_storage = s3_storage
        @manifest = manifest
      end

      # The save can raise after committing (a timeout, say), so the database decides, not the exception.
      def call(uploaded)
        return if referenced?(uploaded)

        s3_storage.delete(id: uploaded.id)
        forget_entry(uploaded)
      end

      private

      attr_reader :file_set, :original, :s3_storage, :manifest

      # When the database cannot be read, keep the upload: the manifest entry still points at it.
      def referenced?(uploaded)
        Hyrax.query_service.find_by(id: original.id).file_identifier == uploaded.id
      rescue StandardError
        true
      end

      # Only an entry naming this upload goes; another process's entry for the file set stays. Failing here
      # must not hide the error that sent the migration to cleanup.
      def forget_entry(uploaded)
        id = file_set.id.to_s
        manifest.delete(id) if manifest.read(id)&.dig(:new_id) == uploaded.id.to_s
      rescue StandardError => e
        Hyrax.logger.warn("S3Migration: could not remove the manifest entry for #{id}: #{e.class}: #{e.message}")
      end
    end
  end
end
