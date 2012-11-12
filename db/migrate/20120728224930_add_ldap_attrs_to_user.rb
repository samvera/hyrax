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

class AddLdapAttrsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :display_name, :string
    add_column :users, :address, :string
    add_column :users, :admin_area, :string
    add_column :users, :department, :string
    add_column :users, :title, :string
    add_column :users, :office, :string
    add_column :users, :chat_id, :string
    add_column :users, :website, :string
    add_column :users, :affiliation, :string
    add_column :users, :telephone, :string
  end

  def self.down
    remove_column :users, :display_name
    remove_column :users, :address
    remove_column :users, :admin_area
    remove_column :users, :department
    remove_column :users, :title
    remove_column :users, :office
    remove_column :users, :chat_id
    remove_column :users, :website
    remove_column :users, :affiliation
    remove_column :users, :telephone
  end
end
