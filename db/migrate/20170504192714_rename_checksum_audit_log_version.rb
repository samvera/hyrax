class RenameChecksumAuditLogVersion < ActiveRecord::Migration[5.0]
  def change
    rename_column :checksum_audit_logs, :version, :checked_uri
  end
end
