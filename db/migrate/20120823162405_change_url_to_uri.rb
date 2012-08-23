class ChangeUrlToUri < ActiveRecord::Migration
  def self.up
    rename_column :subject_local_authority_entries, :url, :uri
  end
  
  def self.down
  end
end
