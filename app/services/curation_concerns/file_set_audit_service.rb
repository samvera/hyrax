module CurationConcerns
  class FileSetAuditService
    attr_reader :file_set
    def initialize(file_set)
      @file_set = file_set
    end

    NO_RUNS = 999

    # provides a human readable version of the audit status
    # This may trigger audits to be run if required
    # @param [Hydra::PCDM::File] file the file to get the audit status for, defaults to the original_file.
    def human_readable_audit_status(file = file_set.original_file)
      audit_stat(file)
    end

    # Check the file by only what is in the audit log.
    # Do not try to access the versions if we do not have access to them.
    # Use this when a file_set is loaded from solr instead of fedora
    def logged_audit_status
      audit_results = ChecksumAuditLog.logs_for(file_set.id, "original_file")
                                      .collect { |result| result["pass"] }

      if audit_results.length > 0
        stat_to_string(audit_results.reduce(true) { |sum, value| sum && value })
      else
        'Audits have not yet been run on this file.'
      end
    end

    # Audits each version of each file if it hasn't been audited recently
    # Returns the set of most recent audit status for each version of the content file
    # @param [Hash] log container for messages, mapping file ids to status
    def audit(log = {})
      file_set.files.each { |f| log[f.id] = audit_file(f) }
      log
    end

    private

      def stat_to_string(stat)
        case stat
        when 0
          'failing'
        when 1
          'passing'
        else
          fail ArgumentError, "Unknown status `#{stat}'"
        end
      end

      # Retrieve or generate the audit check for a file (all versions are checked for versioned files)
      # @param [ActiveFedora::File] file to audit
      # @param [Array] log container for messages
      def audit_file(file, log = [])
        versions = file.has_versions? ? file.versions.all : file
        versions.each { |v| log << audit_file_version(file.id, v.uri) }
        log
      end

      # Retrieve or generate the audit check for a file and provide a human-readable status message.
      # @param [ActiveFedora::File] file to audit
      def audit_stat(file)
        audit_results = audit_file(file).collect { |result| result['pass'] }
        # check how many non runs we had
        non_runs = audit_results.reduce(0) { |sum, value| value == NO_RUNS ? sum + 1 : sum }
        if non_runs == 0
          result = audit_results.reduce(true) { |sum, value| sum && value }
          stat_to_string(result)
        elsif non_runs < audit_results.length
          result = audit_results.reduce(true) { |sum, value| value == NO_RUNS ? sum : sum && value }
          "Some audits have not been run, but the ones run were #{stat_to_string(result)}."
        else
          'Audits have not yet been run on this file.'
        end
      end

      # Retrieve or generate the audit check for a specific version of a file
      # @param [String] file_id used to find the file within its parent object (usually "original_file")
      # @param [String] version_uri the version to be audited (or the file uri for non-versioned files)
      def audit_file_version(file_id, version_uri)
        latest_audit = ChecksumAuditLog.logs_for(file_set.id, file_id).first
        return latest_audit unless needs_audit?(latest_audit)
        AuditJob.perform_later(file_set, file_id, version_uri.to_s)
        latest_audit || ChecksumAuditLog.new(pass: NO_RUNS, file_set_id: file_set.id, file_id: file_id, version: version_uri)
      end

      # Check if time since the last audit is greater than the maximum days allowed between audits
      # @param [ChecksumAuditLog] latest_audit the most recent audit event
      def needs_audit?(latest_audit)
        return true unless latest_audit
        unless latest_audit.updated_at
          logger.warn "***AUDIT*** problem with audit log! Latest Audit is not nil, but updated_at is not set #{latest_audit}"
          return true
        end
        days_since_last_audit(latest_audit) >= CurationConcerns.config.max_days_between_audits
      end

      # Return the number of days since the latest audit event
      # @param [ChecksumAuditLog] latest_audit the most recent audit event
      def days_since_last_audit(latest_audit)
        (DateTime.now - latest_audit.updated_at.to_date).to_i
      end
  end
end
