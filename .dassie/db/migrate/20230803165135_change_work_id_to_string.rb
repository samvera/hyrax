class ChangeWorkIdToString < ActiveRecord::Migration[5.2]
  def change
    change_column :hyrax_counter_metrics, :work_id, :string
  end
end
