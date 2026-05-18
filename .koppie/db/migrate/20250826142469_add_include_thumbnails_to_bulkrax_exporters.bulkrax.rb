# This migration comes from bulkrax (originally 20220412233954)
class AddIncludeThumbnailsToBulkraxExporters < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_exporters, :include_thumbnails, :boolean, default: false unless column_exists?(:bulkrax_exporters, :include_thumbnails)
  end
end
