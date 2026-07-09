# This migration comes from bulkrax (originally 20211220195027)
class AddFileSetCountersToImporterRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_importer_runs, :processed_file_sets, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :processed_file_sets)
    add_column :bulkrax_importer_runs, :failed_file_sets, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :failed_file_sets)
    add_column :bulkrax_importer_runs, :total_file_set_entries, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :total_file_set_entries)
  end
end
