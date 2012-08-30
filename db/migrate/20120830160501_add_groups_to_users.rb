class AddGroupsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :group_list, :string
    add_column :users, :groups_last_update, :datetime
    add_column :users, :ldap_available, :boolean
    add_column :users, :ldap_last_update, :datetime
  end

  def self.down
    remove_column :users, :group_list
    remove_column :users, :groups_last_update
    remove_column :users, :ldap_available
    remove_column :users, :ldap_last_update
  end
end
