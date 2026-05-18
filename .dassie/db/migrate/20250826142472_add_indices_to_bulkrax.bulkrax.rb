# This migration comes from bulkrax (originally 20230608153601)
# This migration comes from bulkrax (originally 20230608153601)
class AddIndicesToBulkrax < ActiveRecord::Migration[5.1]
  def change
    check_and_add_index :bulkrax_entries, :identifier
    check_and_add_index :bulkrax_entries, :type
    check_and_add_index :bulkrax_entries, [:importerexporter_id, :importerexporter_type], name: 'bulkrax_entries_importerexporter_idx'
    check_and_add_index :bulkrax_pending_relationships, :parent_id
    check_and_add_index :bulkrax_pending_relationships, :child_id
    check_and_add_index :bulkrax_statuses, [:statusable_id, :statusable_type], name: 'bulkrax_statuses_statusable_idx'
    check_and_add_index :bulkrax_statuses, [:runnable_id, :runnable_type], name: 'bulkrax_statuses_runnable_idx'
    check_and_add_index :bulkrax_statuses, :error_class
  end

  if RUBY_VERSION =~ /^2/
    def check_and_add_index(table_name, column_name, options = {})
      add_index(table_name, column_name, options) unless index_exists?(table_name, column_name, options)
    end
  elsif RUBY_VERSION =~ /^3/
    def check_and_add_index(table_name, column_name, **options)
      add_index(table_name, column_name, **options) unless index_exists?(table_name, column_name, **options)
    end
  else
    raise "Ruby version #{RUBY_VERSION} is unknown"
  end
end
