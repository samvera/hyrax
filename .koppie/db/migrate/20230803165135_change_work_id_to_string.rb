class ChangeWorkIdToString < ActiveRecord::Migration[6.1]
  def change
    change_column :hyrax_counter_metrics, :work_id, :string
  end
end
