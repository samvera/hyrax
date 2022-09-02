# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20180802220739)
class AddOptimisticLockingToOrmResources < ActiveRecord::Migration[5.1]
  def change
    add_column :orm_resources, :lock_version, :integer
  end
end
