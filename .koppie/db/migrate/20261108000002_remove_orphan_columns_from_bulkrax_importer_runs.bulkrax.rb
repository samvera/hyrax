# This migration comes from bulkrax (originally 20260429000000)
class RemoveOrphanColumnsFromBulkraxImporterRuns < ActiveRecord::Migration[5.2]
  def up
    remove_column :bulkrax_importer_runs, :processed_children, if_exists: true
    remove_column :bulkrax_importer_runs, :failed_children, if_exists: true
    remove_column :bulkrax_importer_runs, :parents, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
