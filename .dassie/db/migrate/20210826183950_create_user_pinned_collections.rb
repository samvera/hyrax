class CreateUserPinnedCollections < ActiveRecord::Migration[5.2]
  def change
    create_table :user_pinned_collections do |t|
      t.integer :user_id
      t.string :collection_id

      t.timestamps
    end
  end
end
