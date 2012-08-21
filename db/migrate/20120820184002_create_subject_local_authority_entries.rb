class CreateSubjectLocalAuthorityEntries < ActiveRecord::Migration
  def self.up  
    create_table :subject_local_authority_entries, :force => true  do |t|
      t.string :label
      t.string :lowerLabel
      t.string :url

      t.timestamps
    end
    
    add_index :subject_local_authority_entries, [:lowerLabel], :name => 'entries_by_lower_label'
    add_index :domain_terms_local_authorities, [:domain_term_id, :local_authority_id], :unique => true, :name => 'domain_terms_by_domain_term_id_and_local_authority'
    
  end
  def self.down
    drop_table :subject_local_authority_entries
    remove_index :subject_local_authority_entries, :name => 'entries_by_lower_label'
    remove_index :domain_terms_local_authorities, :name => 'domain_terms_by_domain_term_id_and_local_authority'
  end
end
