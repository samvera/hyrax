class CreateChecksumAuditLogs < ActiveRecord::Migration
  def self.up
    create_table :checksum_audit_logs do |t|
      t.string :pid
      t.string :dsid
      t.string :version
      t.boolean :pass
      t.string :expected_result
      t.string :actual_result
      t.timestamps
    end
  end

  def self.down
    drop_table :checksum_audit_logs
  end
end
