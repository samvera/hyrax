# This migration comes from mailboxer_engine (originally 20110719110700)
class AddNotifiedObject < ActiveRecord::Migration
  def self.up
    change_table :notifications do |t|
      t.references :notified_object, :polymorphic => true
    end
    remove_columns(:notifications, :object_id, :object_type)
  end

  def self.down
    change_table :notifications do |t|
      t.references :object, :polymorphic => true
    end
    remove_columns(:notifications, :notified_object_id, :notified_object_type)
  end
end
