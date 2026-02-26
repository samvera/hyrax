# This migration comes from bulkrax (originally 20210806065737)
class IncreaseTextSizes < ActiveRecord::Migration[5.1]
  def change
    change_column :bulkrax_entries, :raw_metadata, :text, limit: 16777215
    change_column :bulkrax_entries, :parsed_metadata, :text, limit: 16777215
    change_column :bulkrax_exporters, :parser_fields, :text, limit: 16777215
    change_column :bulkrax_exporters, :field_mapping, :text, limit: 16777215
    change_column :bulkrax_importers, :parser_fields, :text, limit: 16777215
    change_column :bulkrax_importers, :field_mapping, :text, limit: 16777215
    change_column :bulkrax_importer_runs, :invalid_records, :text, limit: 16777215
    change_column :bulkrax_statuses, :error_backtrace, :text, limit: 16777215
  end
end
