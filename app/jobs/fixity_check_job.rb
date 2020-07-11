# frozen_string_literal: true
class FixityCheckJob < Hyrax::ApplicationJob
  # A Job class that runs a fixity check (using Hyrax.config.fixity_service)
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
  # @param file_set_id [FileSet] the id for FileSet parent object of URI being checked.
  # @param file_id [String] File#id, used for logging/reporting.
  def perform(uri, file_set_id:, file_id:)
    run_check(file_set_id, file_id, uri).tap do |audit|
      result   = audit.failed? ? :failure : :success
      file_set = ::FileSet.find(file_set_id)

      Hyrax.publisher.publish('file.set.audited', file_set: file_set, audit_log: audit, result: result)

      # @todo remove this callback call for Hyrax 4.0.0
      if audit.failed? && Hyrax.config.callback.set?(:after_fixity_check_failure)
        Hyrax.config.callback.run(:after_fixity_check_failure,
                                  file_set,
                                  checksum_audit_log: audit, warn: false)
      end
    end
  end

  private

  ##
  # @api private
  def run_check(file_set_id, file_id, uri)
    service = fixity_service_for(id: uri)
    expected_result = service.expected_message_digest

    ChecksumAuditLog.create_and_prune!(passed: service.check, file_set_id: file_set_id, checked_uri: uri.to_s, file_id: file_id, expected_result: expected_result)
  rescue Hyrax::Fixity::MissingContentError
    ChecksumAuditLog.create_and_prune!(passed: false, file_set_id: file_set_id, checked_uri: uri.to_s, file_id: file_id, expected_result: expected_result)
  end

  ##
  # @api private
  # @return [Class]
  def fixity_service_for(id:)
    Hyrax.config.fixity_service.new(id)
  end
end
