class CreateFeatures < ActiveRecord::Migration
  def change
    create_table :sufia_features do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false

      t.timestamps null: false
    end
  end
end
