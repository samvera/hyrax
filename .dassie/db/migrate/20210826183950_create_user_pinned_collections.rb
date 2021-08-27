class CreateUserPinnedCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :user_pinned_collections do |t|
      t.integer :user_id, null: false
      t.string :collection_id, null: false

      t.timestamps
    end
    add_index :user_pinned_collections, :user_id
    add_index :user_pinned_collections, :collection_id
  end
end
