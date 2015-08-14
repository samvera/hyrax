module CurationConcerns
  class GenericFileAuditService
    attr_reader :generic_file
    def initialize(file)
      @generic_file = file
    end

    NO_RUNS = 999

    # provides a human readable version of the audit status
    def human_readable_audit_status(stat)
      case stat
      when 0
        'failing'
      when 1
        'passing'
      else
        stat
      end
    end

    # Audits each version of each file if it hasn't been audited recently
    # Returns the set of most recent audit status for each version of the content file
    # @param [Hash] log container for messages, mapping file ids to status
    def audit(log = {})
      generic_file.files.each { |f| log[f.id] = audit_file(f) }
      log
    end

    private

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
          audit_results.reduce(true) { |sum, value| sum && value }
        elsif non_runs < audit_results.length
          result = audit_results.reduce(true) { |sum, value| value == NO_RUNS ? sum : sum && value }
          "Some audits have not been run, but the ones run were #{human_readable_audit_status(result)}."
        else
          'Audits have not yet been run on this file.'
        end
      end

      # Retrieve or generate the audit check for a specific version of a file
      # @param [String] file_id used to find the file within its parent object (usually "original_file")
      # @param [String] version_uri the version to be audited (or the file uri for non-versioned files)
      def audit_file_version(file_id, version_uri)
        latest_audit = ChecksumAuditLog.logs_for(generic_file.id, file_id).first
        return latest_audit unless needs_audit?(latest_audit)
        CurationConcerns.queue.push(AuditJob.new(generic_file.id, file_id, version_uri))
        latest_audit || ChecksumAuditLog.new(pass: NO_RUNS, generic_file_id: generic_file.id, file_id: file_id, version: version_uri)
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
