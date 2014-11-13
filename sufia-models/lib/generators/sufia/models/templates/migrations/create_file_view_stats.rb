class CreateFileViewStats < ActiveRecord::Migration
  def change
    create_table :file_view_stats do |t|
      t.datetime :date
      t.integer :views
      t.string  :file_id

      t.timestamps
    end
    add_index :file_view_stats, :file_id
  end
end
