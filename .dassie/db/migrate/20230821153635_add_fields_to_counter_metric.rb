class AddFieldsToCounterMetric < ActiveRecord::Migration[5.2]
  def change
    add_column :hyrax_counter_metrics, :title, :string
    add_column :hyrax_counter_metrics, :year_of_publication, :integer, index: true
    add_column :hyrax_counter_metrics, :publisher, :string, index: true
    add_column :hyrax_counter_metrics, :author, :string, index: true
  end
end
