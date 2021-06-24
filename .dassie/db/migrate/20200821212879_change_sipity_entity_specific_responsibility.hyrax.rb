class ChangeSipityEntitySpecificResponsibility < ActiveRecord::Migration[5.2]
  def change
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      change_column :sipity_entity_specific_responsibilities, :entity_id, 'integer USING CAST(entity_id AS integer)'
    else
      change_column :sipity_entity_specific_responsibilities, :entity_id, :integer
    end
  end
end
