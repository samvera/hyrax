# This migration comes from bulkrax (originally 20220301001839)
class CreateBulkraxPendingRelationships < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:bulkrax_pending_relationships)
      create_table :bulkrax_pending_relationships do |t|
        t.belongs_to :bulkrax_importer_run, foreign_key: true, null: false
        t.string :parent_id, null: false
        t.string :child_id, null: false

        t.timestamps
      end
    end
  end
end
