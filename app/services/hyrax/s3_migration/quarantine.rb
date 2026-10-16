# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Handles the disk copy of one manifest entry after migration: move it into <storage>/.quarantine
    # (a rename on the same volume), restore it, and later purge old quarantined files.
    # All actions are dry runs unless apply: true.
    class Quarantine
      DIRECTORY = '.quarantine'

      def self.base_path
        Valkyrie::StorageAdapter.find(:disk).base_path.to_s
      end

      # @return [Array<Integer>] [files purged (or that would be), files too recent]
      def self.purge(apply:, min_age:, base: base_path)
        dir = File.join(base, DIRECTORY)
        old, recent = Dir.glob(File.join(dir, '**', '*')).select { |f| File.file?(f) }
                         .partition { |f| Time.current - File.mtime(f) >= min_age }
        if apply
          old.each { |f| File.delete(f) }
          Dir.glob(File.join(dir, '**', '*', '')).sort.reverse_each { |d| Dir.rmdir(d) if Dir.empty?(d) }
        end
        [old.size, recent.size]
      end

      def initialize(entry, apply: false, verify_sha: true, base: nil, s3_storage: nil)
        @entry = entry
        @apply = apply
        @verify_sha = verify_sha
        @base = base || self.class.base_path
        @s3_storage = s3_storage || Valkyrie::StorageAdapter.find(:repository_s3)
      end

      # @return [Symbol] :quarantined, :already_quarantined, :disk_copy_missing, :outside_base,
      #   :database_changed or :s3_mismatch
      def quarantine
        return :outside_base unless path
        return (File.exist?(destination) ? :already_quarantined : :disk_copy_missing) unless File.exist?(path)
        return :database_changed unless current_identifier == entry[:new_id]
        return :s3_mismatch unless s3_matches_manifest?

        move(path, destination) if apply
        :quarantined
      end

      # @return [Symbol] :rolled_back, :skipped, :disk_copy_gone or :outside_base
      def rollback
        return :outside_base unless path
        return :skipped unless current_identifier == entry[:new_id]
        return :disk_copy_gone unless File.exist?(path) || File.exist?(destination)

        restore if apply
        :rolled_back
      end

      private

      attr_reader :entry, :apply, :verify_sha, :base, :s3_storage

      def path
        candidate = entry[:old_id].to_s.delete_prefix('disk://')
        candidate if candidate.start_with?("#{base}/")
      end

      def destination
        File.join(base, DIRECTORY, path.delete_prefix("#{base}/"))
      end

      def current
        @current ||= Hyrax.query_service.find_by(id: entry[:file_metadata_id])
      end

      def current_identifier
        current.file_identifier.to_s
      end

      def s3_matches_manifest?
        s3_file = s3_storage.find_by(id: entry[:new_id])
        return false unless s3_file.size.to_i == entry[:size]

        !verify_sha || s3_file.checksum(digests: [Digest::SHA256.new]).first == entry[:sha256]
      end

      def move(from, to)
        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.mv(from, to)
        FileUtils.touch(to)
      end

      def restore
        move(destination, path) unless File.exist?(path)
        current.file_identifier = Valkyrie::ID.new(entry[:old_id])
        Hyrax.persister.save(resource: current)
        Hyrax.index_adapter.save(resource: Hyrax.query_service.find_by(id: entry[:file_set_id]))
      end
    end
  end
end
