class AddUserAttributesTable < ActiveRecord::Migration
  def self.up
    create_table :user_attributes do |t|
      t.integer :user_id, :unique => true, :null => false
      t.string :first_name
      t.string :last_name
      t.string :affiliation
      t.string :photo
    end
  end

  def self.down
    drop_table :user_attributes
  end
end
