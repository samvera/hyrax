class ChecksumAuditLog < ActiveRecord::Base
  deprecated_attr_accessible :pass, :pid, :dsid, :version, :created_at

  def ChecksumAuditLog.get_audit_log(version)
    ChecksumAuditLog.find_or_create_by_pid_and_dsid_and_version(:pid => version.pid,
                                                                :dsid => version.dsid,
                                                                :version => version.versionID)
  end

  def ChecksumAuditLog.prune_history(version)
    ## Check to see if there are previous passing logs that we can delete
    # we want to keep the first passing event after a failure, the most current passing event, and all failures so that this table doesn't grow too large
    # Simple way (a little naieve): if the last 2 were passing, delete the first one
    logs = GenericFile.load_instance_from_solr(version.pid).logs(version.dsid)
    list = logs.limit(2)
    if list.size > 1 && (list[0].pass == 1) && (list[1].pass == 1)
      list[0].destroy
    end
  end
end
