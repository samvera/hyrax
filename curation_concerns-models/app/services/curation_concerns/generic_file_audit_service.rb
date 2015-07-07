module CurationConcerns
  class GenericFileAuditService
    attr_reader :generic_file
    def initialize(file)
      @generic_file = file
    end

    NO_RUNS = 999

    # provides a human readable version of the audit status
    def human_readable_audit_status
      stat = audit_stat
      case stat
        when 0
          'failing'
        when 1
          'passing'
        else
          stat
      end
    end

    # TODO: Run audits on all attached files. We're only auditing "content" at tht moment
    # Pushes an AuditJob for each version of content if it hasn't been audited recently
    # Returns the set of most recent audit status for each version of the content file
    def audit
      audit_content([])
    end


    private
      def audit_content(log)
        if generic_file.content.has_versions?
          audit_file_versions("content", log)
        else
          log << audit_file("content", generic_file.content.uri.to_s)
        end
      end

      def audit_file_versions file, log
        generic_file.attached_files[file].versions.all.each do |version|
          log << audit_file(file, version.uri,  version.label)
        end
        log
      end

      def audit_stat
        audit_results = audit.collect { |result| result["pass"] }

        # check how many non runs we had
        non_runs = audit_results.reduce(0) { |sum, value| value == NO_RUNS ? sum += 1 : sum }
        if non_runs == 0
          audit_results.reduce(true) { |sum, value| sum && value }
        elsif non_runs < audit_results.length
          result = audit_results.reduce(true) { |sum, value| value == NO_RUNS ? sum : sum && value }
          "Some audits have not been run, but the ones run were #{result ? 'passing' : 'failing'}."
        else
          'Audits have not yet been run on this file.'
        end
      end

      def audit_file(file, uri, label = nil)
        latest_audit = ChecksumAuditLog.logs_for(generic_file.id, file).first
        return latest_audit unless needs_audit?(latest_audit)
        CurationConcerns.queue.push(AuditJob.new(generic_file.id, file, uri))
        latest_audit || ChecksumAuditLog.new(pass: NO_RUNS, generic_file_id: generic_file.id, dsid: file, version: label)
      end

      def needs_audit?(latest_audit)
        return true unless latest_audit
        unless latest_audit.updated_at
          logger.warn "***AUDIT*** problem with audit log! Latest Audit is not nil, but updated_at is not set #{latest_audit}"
          return true
        end
        days_since_last_audit(latest_audit) >= CurationConcerns.config.max_days_between_audits
      end

      def days_since_last_audit(latest_audit)
        (DateTime.now - latest_audit.updated_at.to_date).to_i
      end

  end
end
