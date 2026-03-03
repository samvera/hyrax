# This migration comes from bulkrax (originally 20181011230201)
class CreateBulkraxImporters < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:bulkrax_importers)
      create_table :bulkrax_importers do |t|
        t.string :name
        t.string :admin_set_id
        t.references :user, foreign_key: false
        t.string :frequency
        t.string :parser_klass
        t.integer :limit
        t.text :parser_fields
        t.text :field_mapping

        t.timestamps
      end
    end
  end
end
