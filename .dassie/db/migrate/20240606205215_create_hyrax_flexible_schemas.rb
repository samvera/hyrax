class CreateHyraxFlexibleSchemas < ActiveRecord::Migration[6.1]
  def change
    create_table :hyrax_flexible_schemas do |t|
      t.string :version, index: { unique: true }
      t.text :profile

      t.timestamps
    end
  end
end
