# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20171204224121)
class CreateInternalResourceIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :orm_resources, :internal_resource
  end
end
