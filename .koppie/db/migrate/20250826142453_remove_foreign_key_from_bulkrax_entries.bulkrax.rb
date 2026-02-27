# This migration comes from bulkrax (originally 20200312190638)
class RemoveForeignKeyFromBulkraxEntries < ActiveRecord::Migration[5.1]
  def change
    remove_foreign_key :bulkrax_entries, :bulkrax_importers if foreign_key_exists?(:bulkrax_entries, :bulkrax_importers)
  end
end
