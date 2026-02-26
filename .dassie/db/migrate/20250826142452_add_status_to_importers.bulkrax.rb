# This migration comes from bulkrax (originally 20200301232856)
class AddStatusToImporters < ActiveRecord::Migration[5.1]
  def change
    if table_exists?(:bulkrax_importers)
      add_column :bulkrax_importers, :last_error, :text unless column_exists?(:bulkrax_importers, :last_error)
      add_column :bulkrax_importers, :last_error_at, :datetime unless column_exists?(:bulkrax_importers, :last_error_at)
      add_column :bulkrax_importers, :last_succeeded_at, :datetime unless column_exists?(:bulkrax_importers, :last_succeeded_at)
    end
  end
end
