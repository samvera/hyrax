# This migration comes from bulkrax (originally 20190729124607)
class CreateBulkraxExporters < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:bulkrax_exporters)
      create_table :bulkrax_exporters do |t|
        t.string :name
        t.references :user, foreign_key: false
        t.string :parser_klass
        t.integer :limit
        t.text :parser_fields
        t.text :field_mapping
        t.string :export_source
        t.string :export_from
        t.string :export_type

        t.timestamps
      end
    end
  end
end
