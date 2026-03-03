# This migration comes from bulkrax (originally 20220303212810)
class AddOrderToBulkraxPendingRelationships < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_pending_relationships, :order, :integer, default: 0 unless column_exists?(:bulkrax_pending_relationships, :order)
  end
end
