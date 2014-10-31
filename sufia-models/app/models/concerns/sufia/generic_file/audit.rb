module Sufia
  module GenericFile
    module Audit
      extend ActiveSupport::Concern

      NO_RUNS = 999

      def audit(force = false)
        logs = []
        self.per_version do |ver|
          logs << audit_each(ver, force)
        end
        logs
      end

      def per_version(&block)
        attached_files.each do |dsid, ds|
          next if ds == full_text
          ds.versions.each do |ver|
            block.call(ver)
          end
        end
      end

      def logs(dsid)
        ChecksumAuditLog.where(dsid: dsid, pid: self.pid).order('created_at desc, id desc')
      end

      def audit!
        audit(true)
      end

      def audit_stat!
        audit_stat(true)
      end

      def audit_stat(force = false)
        logs = audit(force)
        audit_results = logs.collect { |result| result["pass"] }

        # check how many non runs we had
        non_runs = audit_results.reduce(0) { |sum, value| value == NO_RUNS ? sum += 1 : sum }
        if non_runs == 0
          result = audit_results.reduce(true) { |sum, value| sum && value }
          return result
        elsif non_runs < audit_results.length
          result = audit_results.reduce(true) { |sum, value| value == NO_RUNS ? sum : sum && value }
          return 'Some audits have not been run, but the ones run were '+ ((result)? 'passing' : 'failing') + '.'
        else
          return 'Audits have not yet been run on this file.'
        end
      end

      def audit_each(version, force = false)
        latest_audit = logs(version.dsid).first
        return latest_audit unless force || ::GenericFile.needs_audit?(version, latest_audit)

        #  Resque.enqueue(AuditJob, version.pid, version.dsid, version.versionID)
        Sufia.queue.push(AuditJob.new(version.pid, version.dsid, version.versionID))

        # run the find just incase the job has finished already
        latest_audit = logs(version.dsid).first
        latest_audit = ChecksumAuditLog.new(pass: NO_RUNS, pid: version.pid, dsid: version.dsid, version: version.versionID) unless latest_audit
        latest_audit
      end


      module ClassMethods
        def audit!(version)
          ::GenericFile.audit(version, true)
        end

        def audit(version_uri, force = false)
          return { pass: true } # TODO Just skipping the audit for now
          latest_audit = self.find(version_uri).audit_each( version, force)
        end

        def needs_audit?(version, latest_audit)
          if latest_audit and latest_audit.updated_at
            days_since_last_audit = (DateTime.now - latest_audit.updated_at.to_date).to_i
            if days_since_last_audit < Sufia.config.max_days_between_audits
              return false
            end
          else
            logger.warn "***AUDIT*** problem with audit log!  Latest Audit is not nil, but updated_at is not set #{latest_audit}"  unless latest_audit.nil?
          end
          true
        end

        def audit_everything(force = false)
          ::GenericFile.find_each do |gf|
            gf.per_version do |ver|
              ::GenericFile.audit(ver, force)
            end
          end
        end

        def audit_everything!
          ::GenericFile.audit_everything(true)
        end

        def run_audit(version)
          if version.dsChecksumValid
            passing = 1
            ChecksumAuditLog.prune_history(version)
          else
            logger.warn "***AUDIT*** Audit failed for #{version.pid} #{version.versionID}"
            passing = 0
          end
          check = ChecksumAuditLog.create!(pass: passing, pid: version.pid,
                                           dsid: version.dsid, version: version.versionID)
          check
        end
      end
    end
  end
end
