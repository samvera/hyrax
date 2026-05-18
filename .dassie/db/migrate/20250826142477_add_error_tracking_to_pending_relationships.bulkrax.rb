# This migration comes from bulkrax (originally 20240823173525)
class AddErrorTrackingToPendingRelationships < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_pending_relationships, :status_message, :string, default: 'Pending' unless column_exists?(:bulkrax_pending_relationships, :status_message)
  end
end
