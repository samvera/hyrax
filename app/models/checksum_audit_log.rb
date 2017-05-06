class ChecksumAuditLog < ActiveRecord::Base

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

  # Check to see if there are previous passing logs that we can delete
  # we want to keep the first passing event after a failure, the most current passing event,
  # and all failures so that this table doesn't grow too large
  # Simple way (a little naive): if the last 2 were passing, delete the first one
  def self.prune_history(file_set_id, file_id)
    list = logs_for(file_set_id, file_id).limit(2)
    return if list.size <= 1 || list[0].pass != 1 || list[1].pass != 1
    list[0].destroy
  end

  def self.logs_for(file_set_id, file_id)
    ChecksumAuditLog.where(file_set_id: file_set_id, file_id: file_id).order('created_at desc, id desc')
  end
end
