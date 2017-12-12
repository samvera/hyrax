class AddSourceTypeToPermissionTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :permission_templates, :source_type, :string
    add_column :permission_templates, :source_id, :string

    Hyrax::PermissionTemplate.find_each do |permission_template|
      permission_template.source_type = 'admin_set'
      permission_template.source_id = permission_template.admin_set_id
      permission_template.save!
    end

    # If the db is sqlite, don't drop the column or you will get a FK error
    # because of limitation in sqlite
    remove_column :permission_templates, :admin_set_id, :string unless connection.adapter_name.downcase.starts_with?('sqlite')
  end
end
