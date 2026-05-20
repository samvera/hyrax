class AddAdditionalRedirectInfo < ActiveRecord::Migration[6.1]
  def change
    remove_index :hyrax_redirect_paths, :path
    remove_index :hyrax_redirect_paths, :resource_id
    drop_table :hyrax_redirect_paths do |t|
      t.string :path, null: false
      t.string :resource_id, null: false

      t.timestamps
    end

    create_table :hyrax_redirect_paths do |t|
      t.string :from_path, null: false, index: true
      t.string :to_path, null: false, index: true
      t.string :permalink_path, null: false
      t.string :resource_id, null: false, index: true
      t.boolean :is_display_url, null: false, default: false

      t.timestamps
    end

  end
end
