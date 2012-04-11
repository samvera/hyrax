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
