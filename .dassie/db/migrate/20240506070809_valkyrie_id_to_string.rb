class ValkyrieIdToString < ActiveRecord::Migration[6.1]
  def change
    change_column :orm_resources, :id, :text, default: -> { '(uuid_generate_v4())::text' }
  end
end