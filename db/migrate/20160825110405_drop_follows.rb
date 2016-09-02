class DropFollows < ActiveRecord::Migration
  def self.up
    drop_table :follows
  end
end
