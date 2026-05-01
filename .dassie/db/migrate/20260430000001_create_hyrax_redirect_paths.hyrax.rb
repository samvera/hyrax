class CreateHyraxRedirectPaths < ActiveRecord::Migration[5.2]
  def change
    create_table :hyrax_redirect_paths do |t|
      t.string :path, null: false
      t.string :resource_id, null: false

      t.timestamps
    end

    add_index :hyrax_redirect_paths, :path, unique: true
    add_index :hyrax_redirect_paths, :resource_id
  end
end
