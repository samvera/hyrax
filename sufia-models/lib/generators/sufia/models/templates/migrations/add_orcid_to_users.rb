class AddOrcidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :orcid, :string
  end
end
