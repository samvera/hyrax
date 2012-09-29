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

# -*- encoding : utf-8 -*-
class AddUserTypesToBookmarksSearches < ActiveRecord::Migration
  def self.up
    add_column :searches, :user_type, :string
    add_column :bookmarks, :user_type, :string
    Search.reset_column_information
    Bookmark.reset_column_information
    Search.update_all("user_type = 'user'")
    Bookmark.update_all("user_type = 'user'")
  end

  def self.down
    remove_column :searches, :user_type, :string
    remove_column :bookmarks, :user_type, :string
  end
end
