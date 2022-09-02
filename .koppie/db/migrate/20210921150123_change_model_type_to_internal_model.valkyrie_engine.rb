# frozen_string_literal: true
# This migration comes from valkyrie_engine (originally 20170531004548)
class ChangeModelTypeToInternalModel < ActiveRecord::Migration[5.1]
  def change
    rename_column :orm_resources, :resource_type, :internal_resource
  end
end
