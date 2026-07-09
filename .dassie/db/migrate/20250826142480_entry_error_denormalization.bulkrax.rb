# This migration comes from bulkrax (originally 20241203010707)
class EntryErrorDenormalization < ActiveRecord::Migration[5.1]
  def change
    add_column :bulkrax_entries, :error_class, :string unless column_exists?(:bulkrax_entries, :error_class)
    add_column :bulkrax_importers, :error_class, :string unless column_exists?(:bulkrax_importers, :error_class)
    add_column :bulkrax_exporters, :error_class, :string unless column_exists?(:bulkrax_exporters, :error_class)
  end
end
