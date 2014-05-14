class CreateChecksumAuditLogs < ActiveRecord::Migration
  def self.up
    create_table :checksum_audit_logs do |t|
      t.string :pid
      t.string :dsid
      t.string :version
      t.integer :pass
      t.string :expected_result
      t.string :actual_result
      t.timestamps
    end
    add_index :checksum_audit_logs, [:pid, :dsid], name: 'by_pid_and_dsid', order: {created_at: "DESC" }
  end

  def self.down
    remove_index(:checksum_audit_logs, name: 'by_pid_and_dsid')
    drop_table :checksum_audit_logs
  end
end
