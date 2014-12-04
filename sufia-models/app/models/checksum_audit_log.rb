class ChecksumAuditLog < ActiveRecord::Base

  def ChecksumAuditLog.get_audit_log(id, path, version_uri)
    ChecksumAuditLog.find_or_create_by(pid: id, dsid: path, version: version_uri)
  end

  def ChecksumAuditLog.prune_history(id, path)
    # Check to see if there are previous passing logs that we can delete
    # we want to keep the first passing event after a failure, the most current passing event, 
    # and all failures so that this table doesn't grow too large
    # Simple way (a little naieve): if the last 2 were passing, delete the first one
    logs = GenericFile.load_instance_from_solr(id).logs(path)
    list = logs.limit(2)
    if list.size > 1 && (list[0].pass == 1) && (list[1].pass == 1)
      list[0].destroy
    end
  end
end
