# This migration comes from bulkrax (originally 20190601221109)
class AddStatusToEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_entries, :last_error, :text unless column_exists?(:bulkrax_entries, :last_error)
    add_column :bulkrax_entries, :last_error_at, :datetime unless column_exists?(:bulkrax_entries, :last_error_at)

    add_column :bulkrax_entries, :last_succeeded_at, :datetime unless column_exists?(:bulkrax_entries, :last_succeeded_at)

  end
end
