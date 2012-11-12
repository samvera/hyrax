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

# This migration comes from mailboxer_engine (originally 20110511145103)
class CreateMailboxer < ActiveRecord::Migration
  def self.up
    #Tables
    #Conversations
    create_table :conversations do |t|
      t.column :subject, :string, :default => ""
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
    #Receipts
    create_table :receipts do |t|
      t.references :receiver, :polymorphic => true
      t.column :notification_id, :integer, :null => false
      t.column :read, :boolean, :default => false
      t.column :trashed, :boolean, :default => false
      t.column :deleted, :boolean, :default => false
      t.column :mailbox_type, :string, :limit => 25
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
    #Notifications and Messages
    create_table :notifications do |t|
      t.column :type, :string
      t.column :body, :text
      t.column :subject, :string, :default => ""
      t.references :sender, :polymorphic => true
      t.references :object, :polymorphic => true
      t.column :conversation_id, :integer
      t.column :draft, :boolean, :default => false
      t.column :updated_at, :datetime, :null => false
      t.column :created_at, :datetime, :null => false
    end

    #Indexes
    #Conversations
    #Receipts
    add_index "receipts","notification_id"
    #Messages
    add_index "notifications","conversation_id"

    #Foreign keys
    #Conversations
    #Receipts
    add_foreign_key "receipts", "notifications", :name => "receipts_on_notification_id_#{Rails.env}"
    #Messages  
    add_foreign_key "notifications", "conversations", :name => "notifications_on_conversation_id_#{Rails.env}"
  end

  def self.down
    #Tables
    remove_foreign_key "receipts", :name => "receipts_on_notification_id_#{Rails.env}"
    remove_foreign_key "notifications", :name => "notifications_on_conversation_id_#{Rails.env}"

    #Indexes
    drop_table :receipts
    drop_table :conversations
    drop_table :notifications
  end
end
