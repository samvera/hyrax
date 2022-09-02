# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20170124135846)
class AddModelTypeToOrmResources < ActiveRecord::Migration[5.0]
  def change
    add_column :orm_resources, :resource_type, :string
  end
end
