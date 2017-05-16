class ChecksumAuditLog < ActiveRecord::Base

  def failed?
    ! passed?
  end

  # Only the latest rows for a given file_set_id/checked_uri pair.
  # Uses a join, so you might have to be careful combining. You would
  # normally combine this with other conditions, this alone will return
  # LOTS of records.
  def self.latest_checks
    # one crazy SQL trick to get the latest for each fileset/checked_uri combo
    # TODO better index created_at and checked_uri
    joins("LEFT JOIN checksum_audit_logs c2 ON
            (checksum_audit_logs.file_set_id = c2.file_set_id AND
             checksum_audit_logs.checked_uri = c2.checked_uri AND
             checksum_audit_logs.created_at < c2.created_at)").
    # special trick, where there's no other self-join created_at greater -- only the greatest.
    where("c2.id is NULL").
    order("created_at desc, id desc")
  end

  # From all ChecksumAuditLogs related to this file set, returns only
  # the LATEST for each file_set_id/checked_uri pair.
  def self.latest_for_file_set_id(file_set_id)
    # TODO better index created_at and checked_uri
    latest_checks.
    where(file_set_id: file_set_id)
  end

  # Prune old ChecksumAuditLog records. We keep only:
  # * Latest check
  # * failing checks
  # * any checks immediately before or after a failing check,
  #   to provide context on known good dates surrounding failing.
  def self.prune_history(file_set_id, checked_uri:)
    all_logs = logs_for(file_set_id, checked_uri: checked_uri).to_a

    0.upto(all_logs.length - 2).each do |i|
      next if all_logs[i].failed?
      next if i > 0 && all_logs[i - 1].failed?
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
