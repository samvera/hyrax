class AddSourceTypeToPermissionTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :permission_templates, :source_type, :string
    rename_column :permission_templates, :admin_set_id, :source_id
  end
end

