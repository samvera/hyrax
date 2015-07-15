class AuditJob < ActiveFedoraIdBasedJob
  def queue_name
    :audit
  end

  attr_accessor :uri, :id, :association_name

  # URI of the resource to audit.
  # This URI could include the actual resource (e.g. content) and the version to audit:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  # but it could also just be:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content
  # @param [String] id of the parent object
  # @param [String] association_name used to find the file within its parent object (usually "original_file")
  # @param [String] uri of the specific file/version to be audited
  def initialize(id, association_name, uri)
    super(id)
    self.association_name = association_name
    self.uri = uri
  end

  def run
    fixity_ok = false
    log = run_audit
    fixity_ok = (log.pass == 1)
    unless fixity_ok
      if CurationConcerns.config.respond_to?(:after_audit_failure)
        login = generic_file.depositor
        user = User.find_by_user_key(login)
        CurationConcerns.config.after_audit_failure.call(generic_file, user, log.created_at)
      end
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
        ChecksumAuditLog.prune_history(id, association_name)
      else
        logger.warn "***AUDIT*** Audit failed for #{uri} #{error_msg}"
        passing = 0
      end
      ChecksumAuditLog.create!(pass: passing, generic_file_id: id, version: uri, dsid: association_name)
    end

    def logger
      ActiveFedora::Base.logger
    end
end
