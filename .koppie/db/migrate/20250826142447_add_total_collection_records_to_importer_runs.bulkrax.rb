# This migration comes from bulkrax (originally 20191203225129)
class AddTotalCollectionRecordsToImporterRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_importer_runs, :total_collection_entries, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :total_collection_entries)
  end
end
