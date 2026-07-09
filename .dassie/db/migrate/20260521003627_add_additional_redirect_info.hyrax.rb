class AddAdditionalRedirectInfo < ActiveRecord::Migration[5.2]
  def up
    drop_table :hyrax_redirect_paths if table_exists?(:hyrax_redirect_paths)

    create_table :hyrax_redirect_paths do |t|
      t.string  :from_path,      null: false
      t.string  :to_path,        null: false
      t.string  :permalink_path, null: false
      t.string  :resource_id,    null: false
      t.boolean :is_display_url, null: false, default: false

      t.timestamps
    end

    add_index :hyrax_redirect_paths, :from_path, unique: true
    add_index :hyrax_redirect_paths, :resource_id
  end

  def down
    drop_table :hyrax_redirect_paths

    create_table :hyrax_redirect_paths do |t|
      t.string :path,        null: false
      t.string :resource_id, null: false

      t.timestamps
    end

    add_index :hyrax_redirect_paths, :path, unique: true
    add_index :hyrax_redirect_paths, :resource_id
  end
end
