class CreateFeaturedWorks < ActiveRecord::Migration
  def change
    create_table :featured_works do |t|
      t.integer :order, default: 5
      t.string :generic_file_id

      t.timestamps
    end
    add_index :featured_works, :generic_file_id
    add_index :featured_works, :order
  end
end
