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

class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :domain_terms_local_authorities, [:local_authority_id, :domain_term_id], :name => 'dtla_by_ids1'
    add_index :domain_terms_local_authorities, [:domain_term_id, :local_authority_id], :name => 'dtla_by_ids2'
  end
  
  def self.down
    remove_index :domain_terms_local_authorities, :name => 'dtla_by_ids1'
    remove_index :domain_terms_local_authorities, :name => 'dtla_by_ids2'
  end
end
