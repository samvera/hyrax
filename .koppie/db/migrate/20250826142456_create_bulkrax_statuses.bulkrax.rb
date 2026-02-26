# This migration comes from bulkrax (originally 20200818055819)
class CreateBulkraxStatuses < ActiveRecord::Migration[5.1]
  def change
    unless table_exists?(:bulkrax_statuses)
      create_table :bulkrax_statuses do |t|
        t.string :status_message
        t.string :error_class
        t.string :error_message
        t.text :error_backtrace
        t.integer :statusable_id
        t.string :statusable_type
        t.integer :runnable_id
        t.string :runnable_type

        t.timestamps
      end
    end
  end
end
