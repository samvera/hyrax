# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Copies one original file from the disk storage adapter to the S3 repository adapter and
    # switches its identifier only after the copy is verified. Never touches the disk copy.
    # Unexpected errors are raised (so a job can retry); an unverified upload is always removed.
    class FileMigrator
      Result = Struct.new(:status, :message, :entry, keyword_init: true)

      CHUNK_SIZE = 1_048_576

      # @param file_set [Valkyrie::Resource] a file set
      # @param original [Hyrax::FileMetadata] the file set's original file
      def initialize(file_set:, original:, dry_run: false, s3_storage: nil, manifest: nil)
        @file_set = file_set
        @original = original
        @dry_run = dry_run
        @s3_storage = s3_storage || Valkyrie::StorageAdapter.find(:repository_s3)
        @manifest = manifest
      end

      # @return [Result] status is one of :migrated, :would_migrate, :already_migrated,
      #   :unrecognised, :missing, :suspect, :mismatch or :raced
      def call
        skipped = precheck
        return skipped if skipped
        return result(:would_migrate) if dry_run

        migrate
      end

      private

      attr_reader :file_set, :original, :dry_run, :s3_storage

      def manifest
        @manifest ||= Manifest.new
      end

      def identifier
        original.file_identifier.to_s
      end

      def disk_path
        identifier.delete_prefix('disk://')
      end

      def filename
        Array(original.original_filename).first || File.basename(disk_path)
      end

      def precheck
        return result(:already_migrated) if identifier.start_with?('shrine://')
        return result(:unrecognised, identifier) unless identifier.start_with?('disk://')
        return result(:missing, disk_path) unless File.exist?(disk_path)

        suspect = stored_checksum_mismatch
        result(:suspect, "disk file does not match stored checksum #{suspect}") if suspect
      end

      def stored_checksum
        return @stored_checksum if defined?(@stored_checksum)

        @stored_checksum = StoredChecksum.for(original)
      end

      def stored_checksum_mismatch
        stored = stored_checksum
        stored.to_s if stored && disk_digests[:stored] != stored.digest
      end

      # One pass feeds both digests. The S3 adapter then reads the file again to upload it, and once more to
      # verify the upload (its ETag check).
      def disk_digests
        @disk_digests ||= begin
          sha256 = Digest::SHA256.new
          stored = stored_checksum&.digest_class&.new
          File.open(disk_path, 'rb') do |io|
            while (chunk = io.read(CHUNK_SIZE))
              sha256 << chunk
              stored << chunk if stored
            end
          end
          { sha256: sha256.hexdigest, stored: stored&.hexdigest }
        end
      end

      def migrate
        uploaded = nil
        persisted = false
        disk_sha256 = disk_digests[:sha256]
        uploaded = File.open(disk_path, 'rb') { |io| s3_storage.upload(file: io, original_filename: filename, resource: file_set) }
        return result(:mismatch, 'S3 copy does not match disk (size/SHA-256)') unless copy_matches?(uploaded, disk_sha256)

        current = Hyrax.query_service.find_by(id: original.id)
        return result(:raced, 'already migrated by another process') unless current.file_identifier.to_s.start_with?('disk://')

        entry = build_entry(uploaded, disk_sha256)
        manifest.write(entry)
        persist(current, uploaded)
        persisted = true
        result(:migrated, nil, entry)
      ensure
        s3_storage.delete(id: uploaded.id) if uploaded && !persisted
      end

      def copy_matches?(uploaded, disk_sha256)
        s3_storage.find_by(id: uploaded.id).valid?(size: File.size(disk_path), digests: { 'sha256' => disk_sha256 })
      end

      def persist(current, uploaded)
        current.file_identifier = uploaded.id
        Hyrax.persister.save(resource: current)
      end

      def build_entry(uploaded, disk_sha256)
        { file_set_id: file_set.id.to_s,
          file_metadata_id: original.id.to_s, old_id: identifier, new_id: uploaded.id.to_s,
          size: File.size(disk_path), sha256: disk_sha256, at: Time.current.utc.iso8601 }
      end

      def result(status, message = nil, entry = nil)
        Result.new(status:, message:, entry:)
      end
    end
  end
end
