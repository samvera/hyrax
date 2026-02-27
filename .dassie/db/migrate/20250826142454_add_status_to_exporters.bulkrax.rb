# This migration comes from bulkrax (originally 20200326235838)
class AddStatusToExporters < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_exporters, :last_error, :text unless column_exists?(:bulkrax_exporters, :last_error)
    add_column :bulkrax_exporters, :last_error_at, :datetime unless column_exists?(:bulkrax_exporters, :last_error_at)
    add_column :bulkrax_exporters, :last_succeeded_at, :datetime unless column_exists?(:bulkrax_exporters, :last_succeeded_at)
  end
end
