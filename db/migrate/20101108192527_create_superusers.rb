class CreateSuperusers < ActiveRecord::Migration
  def self.up
    create_table :superusers do |t|
      t.integer :user_id, :null=>false
    end
  end

  def self.down
    drop_table :superusers
  end

end
