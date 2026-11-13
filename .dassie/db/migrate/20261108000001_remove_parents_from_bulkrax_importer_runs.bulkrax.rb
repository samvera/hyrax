# This migration comes from bulkrax (originally 20260424081537)
class RemoveParentsFromBulkraxImporterRuns < ActiveRecord::Migration[5.2]
  def up
    remove_column :bulkrax_importer_runs, :parents, if_exists: true
  end

  def down
    add_column :bulkrax_importer_runs, :parents, :text, array: true, default: "{}", unless_exists: true
  end
end
