class ChecksumAuditLog < ActiveRecord::Base
  def ChecksumAuditLog.get_audit_log(version)
    log = ChecksumAuditLog.find_or_create_by_pid_and_dsid_and_version(:pid => version.pid,
                                                                      :dsid => version.dsid,
                                                                      :version => version.versionID)
    log
  end
end  
