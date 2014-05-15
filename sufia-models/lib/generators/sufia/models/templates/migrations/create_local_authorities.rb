class CreateLocalAuthorities < ActiveRecord::Migration
  def self.up
    create_table :local_authority_entries, force: true do |t|
      t.integer :local_authority_id
      t.string :label
      t.string :uri
    end

    create_table :local_authorities, force: true do |t|
      t.string :name, unique: true
    end

    create_table :domain_terms, force: true do |t|
      t.string :model
      t.string :term
    end

    create_table :domain_terms_local_authorities, id: false do |t|
      t.integer :domain_term_id, foreign_key: true
      t.integer :local_authority_id, foreign_key: true
    end

    create_table :subject_local_authority_entries, force: true  do |t|
      t.string :label
      t.string :lowerLabel
      t.string :url
    end

    add_index :local_authority_entries, [:local_authority_id, :label], name: 'entries_by_term_and_label'
    add_index :local_authority_entries, [:local_authority_id, :uri], name: 'entries_by_term_and_uri'
    add_index :domain_terms, [:model, :term], name: 'terms_by_model_and_term'
    add_index :domain_terms_local_authorities, [:local_authority_id, :domain_term_id], name: 'dtla_by_ids1'
    add_index :domain_terms_local_authorities, [:domain_term_id, :local_authority_id], name: 'dtla_by_ids2'
    add_index :subject_local_authority_entries, [:lowerLabel], name: 'entries_by_lower_label'
  end

  def self.down
    drop_table :local_authority_entries
    drop_table :local_authorities
    drop_table :domain_terms
    drop_table :domain_terms_local_authorities
    drop_table :subject_local_authority_entries
    remove_index :local_authority_entries, name: "entries_by_term_and_label"
    remove_index :local_authority_entries, name: "entries_by_term_and_uri"
    remove_index :domain_terms, name: "terms_by_model_and_term"
    remove_index :subject_local_authority_entries, name: 'entries_by_lower_label'
    remove_index :domain_terms_local_authorities, name: 'dtla_by_ids1'
    remove_index :domain_terms_local_authorities, name: 'dtla_by_ids2'
  end
end
