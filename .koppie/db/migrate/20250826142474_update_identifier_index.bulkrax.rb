# This migration comes from bulkrax (originally 20240209070952)
class UpdateIdentifierIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :bulkrax_entries, :identifier if index_exists?(:bulkrax_entries, :identifier )
    add_index :bulkrax_entries, [:identifier, :importerexporter_id, :importerexporter_type], name: 'bulkrax_identifier_idx' unless index_exists?(:bulkrax_entries, [:identifier, :importerexporter_id, :importerexporter_type], name: 'bulkrax_identifier_idx')
  end
end
