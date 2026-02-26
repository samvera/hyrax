# This migration comes from bulkrax (originally 20220609001128)
class RenameBulkraxImporterRunToImporterRun < ActiveRecord::Migration[5.1]
  def up
    if column_exists?(:bulkrax_pending_relationships, :bulkrax_importer_run_id)
      remove_foreign_key :bulkrax_pending_relationships, :bulkrax_importer_runs
      remove_index :bulkrax_pending_relationships, column: :bulkrax_importer_run_id

      rename_column :bulkrax_pending_relationships, :bulkrax_importer_run_id, :importer_run_id

      add_foreign_key :bulkrax_pending_relationships, :bulkrax_importer_runs, column: :importer_run_id
      add_index :bulkrax_pending_relationships, :importer_run_id, name: 'index_bulkrax_pending_relationships_on_importer_run_id'
    end
  end

  def down
    rename_column :bulkrax_pending_relationships, :importer_run_id, :bulkrax_importer_run_id
  end
end
