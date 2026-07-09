# This migration comes from bulkrax (originally 20191204191623)
class AddChildrenToImporterRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_importer_runs, :processed_children, :integer, default: 0 unless column_exists?(:bulkrax_importer_runs, :processed_children)
    add_column :bulkrax_importer_runs, :failed_children, :integer, default: 0  unless column_exists?(:bulkrax_importer_runs, :failed_children)
  end
end
