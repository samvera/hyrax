# frozen_string_literal: true

class UserRoles < ActiveRecord::Migration[5.0]
  def up
    create_table :roles do |t|
      t.string :name
    end
    create_table :roles_users, id: false do |t|
      t.references :role
      t.references :user
    end
    add_index :roles_users, %i[role_id user_id]
    add_index :roles_users, %i[user_id role_id]
  end

  def down
    drop_table :roles_users
    drop_table :roles
  end
end
