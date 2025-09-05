class AddContextsToHyraxFlexibleSchemas < ActiveRecord::Migration[6.1]
  def change
    add_column :hyrax_flexible_schemas, :contexts, :text unless column_exists?(:hyrax_flexible_schemas, :contexts)
  end
end
