# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    add_index :checksum_audit_logs, [:pid, :dsid], :name=>'by_pid_and_dsid', :order => {:created_at => "DESC" }
    
  end

  def self.down
    remove_index(:checksum_audit_logs, :name => 'by_pid_and_dsid')
    drop_table :checksum_audit_logs
  end
end
