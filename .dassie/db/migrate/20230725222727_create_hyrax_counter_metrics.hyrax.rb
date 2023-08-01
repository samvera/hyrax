class CreateHyraxCounterMetrics < ActiveRecord::Migration[6.0]
  def change
    create_table :hyrax_counter_metrics do |t|
      t.string :worktype
      t.string :resource_type
      t.integer :work_id
      t.date :date
      t.integer :total_item_investigations
      t.integer :total_item_requests

      t.timestamps
    end
  end
end
