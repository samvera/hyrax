class AddExternalKeyToContentBlocks < ActiveRecord::Migration
  def change
    add_column :content_blocks, :external_key, :string
    remove_index :content_blocks, :name
  end
end
