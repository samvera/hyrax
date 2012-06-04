class ChangeAuditColumnType < ActiveRecord::Migration
  def self.up
    change_column :checksum_audit_logs, :pass, :integer
  end
  
  def self.down
  end
end
