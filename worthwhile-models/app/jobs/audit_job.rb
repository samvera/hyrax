class AuditJob < ActiveFedoraIdBasedJob
  def queue_name
    :audit
  end

  PASS = 'Passing Audit Run'
  FAIL = 'Failing Audit Run'

  attr_accessor :uri, :id, :path

  # URI of the resource to audit.
  # This URI could include the actual resource (e.g. content) and the version to audit:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  # but it could also just be:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content
  def initialize(id, path, uri)
    super(id)
    self.path = path
    self.uri = uri
  end

  def run
    fixity_ok = false
    log = run_audit
    fixity_ok = (log.pass == 1)
    unless fixity_ok
      # send the user a message about the failing audit
      login = generic_file.depositor
      user = User.find_by_user_key(login)
      logger.warn "User '#{login}' not found" unless user
      job_user = User.audituser()
      file_title = generic_file.title.first
      message = "The audit run at #{log.created_at} for #{file_title} (#{uri}) failed."
      subject = FAIL
      job_user.send_message(user, message, subject)
    end
    fixity_ok
  end

  protected

    def run_audit
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
      ChecksumAuditLog.create!(pass: passing, generic_file_id: id, version: uri, dsid: path)
    end

    def logger
      ActiveFedora::Base.logger
    end
end
