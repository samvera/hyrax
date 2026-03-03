# This migration comes from bulkrax (originally 20190729134158)
class CreateBulkraxExporterRuns < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:bulkrax_exporter_runs)
      create_table :bulkrax_exporter_runs do |t|
        t.references :exporter, foreign_key: { to_table: :bulkrax_exporters }
        t.integer :total_records, default: 0
        t.integer :enqueued_records, default: 0
        t.integer :processed_records, default: 0
        t.integer :deleted_records, default: 0
        t.integer :failed_records, default: 0
      end
    end
  end
end
