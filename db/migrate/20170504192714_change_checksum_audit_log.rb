class ChangeChecksumAuditLog < ActiveRecord::Migration[5.0]
  def change
    rename_column :checksum_audit_logs, :version, :checked_uri
    change_column :checksum_audit_logs, :pass, :boolean
    rename_column :checksum_audit_logs, :pass, :passed
    add_index     :checksum_audit_logs, :checked_uri
  end
end
