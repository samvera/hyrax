# This migration comes from bulkrax (originally 20191204223857)
class ChangeTotalRecordsToTotalWorkEntries < ActiveRecord::Migration[5.1]
  def change
    rename_column :bulkrax_importer_runs, :total_records, :total_work_entries if column_exists?(:bulkrax_importer_runs, :total_records)
    rename_column :bulkrax_exporter_runs, :total_records, :total_work_entries if column_exists?(:bulkrax_exporter_runs, :total_records)
  end
end
