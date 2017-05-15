module Hyrax
  class FileSetFixityCheckService
    attr_reader :file_set, :id

    # @param file_set [ActiveFedora::Base, String] file_set
    def initialize(file_set)
      if file_set.is_a?(String)
        @id = file_set
      else
        @id = file_set.id
        @file_set = file_set
      end
    end

    NO_RUNS = 999

    # Return current fixity status for this FileSet based on
    # ChecksumAuditLog records on file.
    # TODO: This method is on this class for legacy, callers
    # should just use FixityStatusService directly.
    def logged_fixity_status
      FixityStatusService.new(file_set.id).file_set_status
    end

    # Fixity checks each version of each file if it hasn't been checked recently
    # Returns the set of most recent fixity check status for each version of the
    # content file
    # @param [Hash] log container for messages, mapping file ids to status
    def fixity_check(log = {})
      file_set.files.each { |f| log[f.id] = fixity_check_file(f) }
      log
    end

    private
      # Retrieve or generate the fixity check for a file (all versions are checked for versioned files)
      # @param [ActiveFedora::File] file to fixity check
      # @param [Array] log container for messages
      def fixity_check_file(file, log = [])
        versions = file.has_versions? ? file.versions.all : file
        versions.each { |v| log << fixity_check_file_version(file.id, v.uri) }
        log
      end

      # Retrieve or generate the fixity check for a specific version of a file
      # @param [String] file_id used to find the file within its parent object (usually "original_file")
      # @param [String] version_uri the version to be fixity checked (or the file uri for non-versioned files)
      def fixity_check_file_version(file_id, version_uri)
        latest_fixity_check = ChecksumAuditLog.logs_for(file_set.id, file_id).first
        return latest_fixity_check unless needs_fixity_check?(latest_fixity_check)
        FixityCheckJob.perform_later(version_uri.to_s, file_set_id: file_set.id, file_id: file_id)
        latest_fixity_check || ChecksumAuditLog.new(pass: NO_RUNS, file_set_id: file_set.id, file_id: file_id, checked_uri: version_uri)
      end

      # Check if time since the last fixity check is greater than the maximum days allowed between fixity checks
      # @param [ChecksumAuditLog] latest_fixity_check the most recent fixity check
      def needs_fixity_check?(latest_fixity_check)
        return true unless latest_fixity_check
        unless latest_fixity_check.updated_at
          logger.warn "***FIXITY*** problem with fixity check log! Latest Fixity check is not nil, but updated_at is not set #{latest_fixity_check}"
          return true
        end
        days_since_last_fixity_check(latest_fixity_check) >= Hyrax.config.max_days_between_fixity_checks
      end

      # Return the number of days since the latest fixity check
      # @param [ChecksumAuditLog] latest_fixity_check the most recent fixity check
      def days_since_last_fixity_check(latest_fixity_check)
        (DateTime.current - latest_fixity_check.updated_at.to_date).to_i
      end

      # Loads the FileSet from Fedora if needed
      def file_set
        @file_set ||= ::FileSet.find(id)
      end
  end
end
