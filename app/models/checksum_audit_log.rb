class ChecksumAuditLog < ActiveRecord::Base
  def ChecksumAuditLog.get_audit_log(version)
    log = ChecksumAuditLog.find_or_create_by_pid_and_dsid_and_version(:pid => version.pid,
                                                                      :dsid => version.dsid,
                                                                      :version => version.versionID)
    log
  end

  def ChecksumAuditLog.prune_history(version)
    ## Check to see if there are previous passing logs that we can delete
    # we want to keep the first passing event after a failure, the most current passing event, and all failures so that this table doesn't grow too large
    # Simple way (a little naieve): if the last 2 were passing, delete the first one
    logs = ChecksumAuditLog.where(:dsid=>version.dsid, :pid=>version.pid).order('created_at desc')
    list = logs.limit(2)
    if list.size > 1 && list[0].pass && list[1].pass
      list[0].delete 
    end
  end
end  
