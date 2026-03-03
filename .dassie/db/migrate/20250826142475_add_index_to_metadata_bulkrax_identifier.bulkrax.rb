# This migration comes from bulkrax (originally 20240307053156)
class AddIndexToMetadataBulkraxIdentifier < ActiveRecord::Migration[5.2]
  def up
    return unless table_exists?(:orm_resources)
    return if index_exists?(:orm_resources, "(((metadata -> 'bulkrax_identifier'::text) ->> 0))", name: 'index_on_bulkrax_identifier')

    # This creates an expression index on the first element of the bulkrax_identifier array
    add_index :orm_resources,
              "(metadata -> 'bulkrax_identifier' ->> 0)",
              name: 'index_on_bulkrax_identifier',
              where: "metadata -> 'bulkrax_identifier' IS NOT NULL"
  end

  def down
    return unless table_exists?(:orm_resources)

    remove_index :orm_resources, name: 'index_on_bulkrax_identifier'
  end
end
