class CreateFeaturedWorks < ActiveRecord::Migration
  def change
    create_table :featured_works do |t|
      t.integer :order, default: 5
      t.string :generic_work_id

      t.timestamps null: false
    end
    add_index :featured_works, :generic_work_id
    add_index :featured_works, :order
  end
end
