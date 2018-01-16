class UpdateNullSourceTypeOnPermissionTemplates < ActiveRecord::Migration[5.0]
  def up
    Hyrax::PermissionTemplate.find_each do |permission_template|
      permission_template.source_type = 'admin_set' if permission_template.source_type.nil?
      permission_template.save!
    end
  end
end
