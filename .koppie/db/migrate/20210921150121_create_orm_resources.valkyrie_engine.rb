# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20161007101725)
class CreateOrmResources < ActiveRecord::Migration[5.0]
  def options
    if ENV["VALKYRIE_ID_TYPE"] == "string"
      { id: :text, default: -> { '(uuid_generate_v4())::text' } }
    else
      { id: :uuid }
    end
  end

  def change
    create_table :orm_resources, **options do |t|
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :orm_resources, :metadata, using: :gin
  end
end
