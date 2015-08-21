class CreateChecksumAuditLogs < ActiveRecord::Migration
  def self.up
    create_table :checksum_audit_logs do |t|
      t.string :generic_file_id
      t.string :file_id
      t.string :version
      t.integer :pass
      t.string :expected_result
      t.string :actual_result
      t.timestamps
    end
    add_index :checksum_audit_logs, [:generic_file_id, :file_id], name: 'by_generic_file_id_and_file_id', order: { created_at: 'DESC' }
  end

  def self.down
    remove_index(:checksum_audit_logs, name: 'by_generic_file_id_and_file_id')
    drop_table :checksum_audit_logs
  end
end
