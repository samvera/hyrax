class RemoveTimestampsFromAuthorities < ActiveRecord::Migration
  def self.up
    remove_column :local_authority_entries, :created_at
    remove_column :local_authority_entries, :updated_at
    remove_column :local_authorities, :created_at
    remove_column :local_authorities, :updated_at
    remove_column :domain_terms, :created_at
    remove_column :domain_terms, :updated_at
  end

  def self.down
    add_column :local_authority_entries, :created_at, :timestamp
    add_column :local_authority_entries, :updated_at, :timestamp
    add_column :local_authorities, :created_at, :timestamp
    add_column :local_authorities, :updated_at, :timestamp
    add_column :domain_terms, :created_at, :timestamp
    add_column :domain_terms, :updated_at, :timestamp
  end
end
