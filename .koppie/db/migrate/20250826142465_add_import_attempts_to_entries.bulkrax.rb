# This migration comes from bulkrax (originally 20220118001339)
class AddImportAttemptsToEntries < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_entries, :import_attempts, :integer, default: 0 unless column_exists?(:bulkrax_entries, :import_attempts)
  end
end
