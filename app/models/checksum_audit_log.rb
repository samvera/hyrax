class ChecksumAuditLog < ActiveRecord::Base
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
