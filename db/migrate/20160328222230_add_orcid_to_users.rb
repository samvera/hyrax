class AddOrcidToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :orcid, :string
  end
end
