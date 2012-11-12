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

class CreateLocalAuthorities < ActiveRecord::Migration
  def self.up
    create_table :local_authority_entries, :force => true do |t|
      t.integer :local_authority_id
      t.string :label
      t.string :uri
      t.timestamps
    end

    create_table :local_authorities, :force => true do |t|
      t.string :name, :unique => true
      t.timestamps
    end

    create_table :domain_terms, :force => true do |t|
      t.string :model
      t.string :term
      t.timestamps
    end

    create_table :domain_terms_local_authorities, :id => false do |t|
      t.integer :domain_term_id, :foreign_key => true
      t.integer :local_authority_id, :foreign_key => true
    end

    add_index :local_authority_entries, [:local_authority_id, :label], :name => 'entries_by_term_and_label'
    add_index :local_authority_entries, [:local_authority_id, :uri], :name => 'entries_by_term_and_uri'
    add_index :domain_terms, [:model, :term], :name => 'terms_by_model_and_term'
  end

  def self.down
    drop_table :local_authority_entries
    drop_table :local_authorities
    drop_table :domain_terms
    drop_table :domain_terms_local_authorities
    remove_index :local_authority_entries, :name => "entries_by_term_and_label"
    remove_index :local_authority_entries, :name => "entries_by_term_and_uri"
    remove_index :domain_terms, :name => "terms_by_model_and_term"
  end
end
