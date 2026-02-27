# This migration comes from bulkrax (originally 20240208005801)
class DenormalizeStatusMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :bulkrax_entries, :status_message, :string, default: 'Pending' unless column_exists?(:bulkrax_entries, :status_message)
    add_column :bulkrax_importers, :status_message, :string, default: 'Pending' unless column_exists?(:bulkrax_importers, :status_message)
    add_column :bulkrax_exporters, :status_message, :string, default: 'Pending' unless column_exists?(:bulkrax_exporters, :status_message)
  end
end
