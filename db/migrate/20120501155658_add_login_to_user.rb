class AddLoginToUser < ActiveRecord::Migration
  def change
    add_column :users, :login, :string, :null=>false, :default=>''
    change_column :users, :email, :string, :null=>true
    change_column :users, :encrypted_password, :string, :null=>true
    add_index :users, :login, :unique=>true
  end
end
