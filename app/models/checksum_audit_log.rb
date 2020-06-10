# frozen_string_literal: true
class ChecksumAuditLog < ActiveRecord::Base
  def failed?
    !passed?
  end

  # Only the latest rows for a given file_set_id/checked_uri pair.
  # Uses a join, so you might have to be careful combining. You would
  # normally combine this with other conditions, this alone will return
  # LOTS of records.
  def self.latest_checks
    # one crazy SQL trick to get the latest for each fileset/checked_uri combo
    # where there's no other self-join created_at greater -- only the greatest.
    joins("LEFT JOIN checksum_audit_logs c2 ON
            (checksum_audit_logs.file_set_id = c2.file_set_id AND
             checksum_audit_logs.checked_uri = c2.checked_uri AND
             checksum_audit_logs.created_at < c2.created_at)")
      .where("c2.id is NULL")
      .order("created_at desc, id desc")
  end

  # From all ChecksumAuditLogs related to this file set, returns only
  # the LATEST for each file_set_id/checked_uri pair.
  def self.latest_for_file_set_id(file_set_id)
    latest_checks.where(file_set_id: file_set_id)
  end

  # Responsible for coordinating the creation (and possible pruning) of checksum log entries
  #
  # @param [Boolean] passed - Did the fixity test pass?
  # @param [#to_s] checked_uri - Which URI did we check?
  # @param [String] file_set_id - The file set ID of the file we are checking
  # @param [String] file_id - The file ID that was checked
  # @param [String] expected_result - The expected checksum
  # @return [ChecksumAuditLog]
  # @see .prune_history
  def self.create_and_prune!(passed:, checked_uri:, file_set_id:, file_id:, expected_result:)
    log = create!(passed: passed, checked_uri: checked_uri, file_set_id: file_set_id, file_id: file_id, expected_result: expected_result)
    # A short-circuit. Given that .prune_history keeps all failing logs, there is no need to call prune history
    # unless the check passed.
    prune_history(file_set_id, checked_uri: checked_uri) if log.passed?
    log
  end

  # Prune old ChecksumAuditLog records. We keep only:
  # * Latest check
  # * failing checks
  # * any checks immediately before or after a failing check,
  #   to provide context on known good dates surrounding failing.
  def self.prune_history(file_set_id, checked_uri:)
    all_logs = logs_for(file_set_id, checked_uri: checked_uri).reorder("created_at asc").to_a

    0.upto(all_logs.length - 2).each do |i|
      next if all_logs[i].failed?
      next if i.positive? && all_logs[i - 1].failed?
      next if all_logs[i + 1].failed?

      all_logs[i].destroy!
    end
  end

  # All logs for a particular file or version in a give file set, sorted
  # by date descending.
  def self.logs_for(file_set_id, checked_uri:)
    ChecksumAuditLog.where(file_set_id: file_set_id, checked_uri: checked_uri).order('created_at desc, id desc')
  end
end
