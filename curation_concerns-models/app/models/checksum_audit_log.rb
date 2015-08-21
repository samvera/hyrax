class ChecksumAuditLog < ActiveRecord::Base
  def self.get_audit_log(id, path, version_uri)
    ChecksumAuditLog.find_or_create_by(generic_file_id: id, file_id: path, version: version_uri)
  end

  # Check to see if there are previous passing logs that we can delete
  # we want to keep the first passing event after a failure, the most current passing event,
  # and all failures so that this table doesn't grow too large
  # Simple way (a little naieve): if the last 2 were passing, delete the first one
  def self.prune_history(id, path)
    list = logs_for(id, path).limit(2)
    if list.size > 1 && (list[0].pass == 1) && (list[1].pass == 1)
      list[0].destroy
    end
  end

  def self.logs_for(id, path)
    ChecksumAuditLog.where(generic_file_id: id, file_id: path).order('created_at desc, id desc')
  end
end
