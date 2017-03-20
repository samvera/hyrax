class PermissionTemplateChangeColumnWorkflowName < ActiveRecord::Migration
  def change
    change_column_null :permission_templates, :workflow_name, false
  end
end
