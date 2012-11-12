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

class ActsAsFollowerMigration < ActiveRecord::Migration
  def self.up
    create_table :follows, :force => true do |t|
      t.references :followable, :polymorphic => true, :null => false
      t.references :follower,   :polymorphic => true, :null => false
      t.boolean :blocked, :default => false, :null => false
      t.timestamps
    end

    add_index :follows, ["follower_id", "follower_type"],     :name => "fk_follows"
    add_index :follows, ["followable_id", "followable_type"], :name => "fk_followables"
  end

  def self.down
    drop_table :follows
  end
end
