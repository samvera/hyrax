# frozen_string_literal: true
# This migration comes from bulkrax (originally 20241205212513)
class FasterFirstEntry < ActiveRecord::Migration[5.2]
  def change
    add_index :bulkrax_entries, [:importerexporter_id, :importerexporter_type, :id], name: 'index_bulkrax_entries_on_importerexporter_id_type_and_id' unless index_exists?(:bulkrax_entries, [:importerexporter_id, :importerexporter_type, :id],
      name: 'index_bulkrax_entries_on_importerexporter_id_type_and_id')
  end
end
