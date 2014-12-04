module Sufia
  module GenericFile
    module Audit
      extend ActiveSupport::Concern

      NO_RUNS = 999

      def audit(force = false)
        # TODO: This needs to be updated to pass enough information to audit_each
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

      def logs(path)
        ChecksumAuditLog.where(pid: self.pid, dsid: path).order('created_at desc, id desc')
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
        latest_audit = logs.first
        return latest_audit unless force || ::GenericFile.needs_audit?(version, latest_audit)

        # TODO: This needs to be updated to pass gf.id, datastream, and version_id
        Sufia.queue.push(AuditJob.new(version, 'content', version))

        # run the find just incase the job has finished already
        latest_audit = logs.first
        latest_audit = ChecksumAuditLog.new(pass: NO_RUNS, pid: version, version: version) unless latest_audit
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

        def run_audit(id, path, uri)
          begin
            fixity_ok = ActiveFedora::FixityService.new(uri).check
          rescue Ldp::NotFound 
            error_msg = "resource not found"
          end

          if fixity_ok
            passing = 1
            ChecksumAuditLog.prune_history(id, path)
          else
            logger.warn "***AUDIT*** Audit failed for #{uri} #{error_msg}"
            passing = 0
          end
          check = ChecksumAuditLog.create!(pass: passing, pid: id, version: uri, dsid: path)
          check
        end
      end
    end
  end
end
