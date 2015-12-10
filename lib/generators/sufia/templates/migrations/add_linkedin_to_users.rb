class AddLinkedinToUsers < ActiveRecord::Migration
  def change
    add_column :users, :linkedin_handle, :string
  end
end
