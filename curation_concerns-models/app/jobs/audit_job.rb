class AuditJob < ActiveFedoraIdBasedJob
  queue_as :audit

  attr_accessor :uri, :id, :file_id

  # URI of the resource to audit.
  # This URI could include the actual resource (e.g. content) and the version to audit:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  # but it could also just be:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content
  # @param [String] id of the parent object
  # @param [String] file_id used to find the file within its parent object (usually "original_file")
  # @param [String] uri of the specific file/version to be audited
  def perform(id, file_id, uri)
    @id = id
    @file_id = file_id
    @uri = uri
    log = run_audit
    fixity_ok = log.pass == 1
    unless fixity_ok
      if CurationConcerns.config.callback.set?(:after_audit_failure)
        login = file_set.depositor
        user = User.find_by_user_key(login)
        CurationConcerns.config.callback.run(:after_audit_failure, file_set, user, log.created_at)
      end
    end
    fixity_ok
  end

  protected

    def run_audit
      begin
        fixity_ok = ActiveFedora::FixityService.new(uri).check
      rescue Ldp::NotFound
        error_msg = 'resource not found'
      end

      if fixity_ok
        passing = 1
        ChecksumAuditLog.prune_history(id, file_id)
      else
        logger.warn "***AUDIT*** Audit failed for #{uri} #{error_msg}"
        passing = 0
      end
      ChecksumAuditLog.create!(pass: passing, file_set_id: id, version: uri, file_id: file_id)
    end

  private

    def logger
      ActiveFedora::Base.logger || CurationConcerns::NullLogger.new
    end
end
