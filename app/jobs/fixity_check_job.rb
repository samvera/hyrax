class FixityCheckJob < Hyrax::ApplicationJob
  # A Job class that runs a fixity check (using ActiveFedora::FixityService,
  # which contacts fedora and requests a fixity check), and stores the results
  # in an ActiveRecord ChecksumAuditLog row. It also prunes old ChecksumAuditLog
  # rows after creating a new one, to keep old ones you don't care about from
  # filling up your db.
  #
  # The uri passed in is a fedora URI that fedora can run fixity check on.
  # It's normally a version URI like:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content/fcr:versions/version1
  #
  # But could theoretically be any URI fedora can fixity check on, like a file uri:
  #     http://localhost:8983/fedora/rest/test/a/b/c/abcxyz/content
  #
  # The file_set_id and file_id are used only for logging context in the
  # ChecksumAuditLog, and determining what old ChecksumAuditLogs can
  # be pruned.
  #
  # If calling async as a background job, return value is irrelevant, but
  # if calling sync with `perform_now`, returns the ChecksumAuditLog
  # record recording the check.
  #
  # @param uri [String] uri - of the specific file/version to fixity check
  # @param file_set_id [Valkyrie::ID] the id for FileSet parent object of URI being checked.
  # @param file_id [String] File#id, used for logging/reporting.
  def perform(uri, file_set_id:, file_id:)
    uri = uri.to_s # sometimes we get an RDF::URI gah
    log = run_check(file_set_id, file_id, uri)

    if log.failed? && Hyrax.config.callback.set?(:after_fixity_check_failure)
      file_set = Hyrax::Queries.find_file_set(id: file_set_id)
      Hyrax.config.callback.run(:after_fixity_check_failure,
                                file_set,
                                checksum_audit_log: log)
    end

    log
  end

  private

    def run_check(file_set_id, file_id, uri)
      file_node = Hyrax::Queries.find_by(id: file_id)
      stored_file = Valkyrie::StorageAdapter.find_by(id: file_node.file_identifiers[0])
      # TODO: determine which digest to work with: sha1 vs sha256
      fixity_ok = stored_file.valid?(size: file_node.size.first, digests: { sha256: file_node.checksum.first })
      expected_result = file_node.checksum.first

      log = ChecksumAuditLog.create_and_prune!(passed: fixity_ok, file_set_id: file_set_id.to_s, checked_uri: uri, file_id: file_id.to_s, expected_result: expected_result)
      # Note that the after_fixity_check_failure will be called if the fixity check fail. This
      # logging is for additional information related to the failure. Wondering if we should
      # also include the error message?
      Rails.logger.error "FIXITY CHECK FAILURE: Fixity failed for #{uri} #{error_msg}: #{log}" unless fixity_ok
      log
    end
end
