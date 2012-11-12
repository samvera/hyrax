# -*- coding: utf-8 -*-
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

# This migration comes from mailboxer_engine (originally 20110912163911)
class AddNotificationCode < ActiveRecord::Migration
  def self.up
    change_table :notifications do |t|
      t.string :notification_code, :default => nil
    end
  end

  def self.down
    change_table :notifications do |t|
      t.remove :notification_code
    end
  end
end
