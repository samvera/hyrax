class ChangeAuditLogPidToGenericFileId < ActiveRecord::Migration
  def change
    rename_column :checksum_audit_logs, :pid, :generic_file_id unless ChecksumAuditLog.column_names.include?('generic_file_id')
  end
end
