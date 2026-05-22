# This migration comes from bulkrax (originally 20220119213325)
class AddWorkCountersToImporterRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_importer_runs, :processed_works, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :processed_works)
    add_column :bulkrax_importer_runs, :failed_works, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :failed_works)
  end
end
