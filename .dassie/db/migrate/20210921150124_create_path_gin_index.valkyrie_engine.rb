# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20171011224121)
class CreatePathGinIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :orm_resources, 'metadata jsonb_path_ops', using: :gin
  end
end
