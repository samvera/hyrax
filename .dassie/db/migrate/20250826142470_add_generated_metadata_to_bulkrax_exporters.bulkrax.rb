# This migration comes from bulkrax (originally 20220413180915)
class AddGeneratedMetadataToBulkraxExporters < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_exporters, :generated_metadata, :boolean, default: false unless column_exists?(:bulkrax_exporters, :generated_metadata)
  end
end
