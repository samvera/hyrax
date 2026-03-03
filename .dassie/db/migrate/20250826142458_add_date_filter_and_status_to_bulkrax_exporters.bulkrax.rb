# This migration comes from bulkrax (originally 20201106014204)
class AddDateFilterAndStatusToBulkraxExporters < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_exporters, :start_date, :date unless column_exists?(:bulkrax_exporters, :start_date)
    add_column :bulkrax_exporters, :finish_date, :date unless column_exists?(:bulkrax_exporters, :finish_date)
    add_column :bulkrax_exporters, :work_visibility, :string unless column_exists?(:bulkrax_exporters, :work_visibility)
  end
end
