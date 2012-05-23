# This migration comes from mailboxer_engine (originally 20111204163911)
class AddAttachments < ActiveRecord::Migration
  def change
    add_column :notifications, :attachment, :string
  end
end
