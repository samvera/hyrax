class AddPermissionTemplateToSipityWorkflow < ActiveRecord::Migration
  def change
    add_column :sipity_workflows, :permission_template_id, :integer, index: true
    remove_index :sipity_workflows, :name
    add_index :sipity_workflows, [:permission_template_id, :name], name: :index_sipity_workflows_on_permission_template_and_name, unique: true
  end
end
