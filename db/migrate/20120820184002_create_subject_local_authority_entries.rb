class CreateSubjectLocalAuthorityEntries < ActiveRecord::Migration
  # TODO: This method should ultimately be monkeypatched onto AR::Migration and made available to all migrations
  def truncate_table(table)
    # Do not touch the schema_migrations table, even if specified
    return if table == "schema_migrations"
    adapter = ActiveRecord::Base.configurations[::Rails.env]["adapter"]
    case adapter
    when "mysql", "mysql2", "postgresql"
      ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
    when "sqlite", "sqlite3"
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
      ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='#{table}'")
      ActiveRecord::Base.connection.execute("VACUUM")
    end
  end

  def self.up
    create_table :subject_local_authority_entries, :force => true  do |t|
      t.string :label
      t.string :lowerLabel
      t.string :url

      t.timestamps
    end
    truncate_table 'domain_terms_local_authorities'
    add_index :subject_local_authority_entries, [:lowerLabel], :name => 'entries_by_lower_label'
    add_index :domain_terms_local_authorities, [:domain_term_id, :local_authority_id], :unique => true, :name => 'domain_terms_by_domain_term_id_and_local_authority'
  end

  def self.down
    drop_table :subject_local_authority_entries
    remove_index :subject_local_authority_entries, :name => 'entries_by_lower_label'
    remove_index :domain_terms_local_authorities, :name => 'domain_terms_by_domain_term_id_and_local_authority'
  end
end
