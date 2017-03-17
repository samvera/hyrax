class AddAllowsAccessGrantToWorkflow < ActiveRecord::Migration
  def change
    add_column :sipity_workflows, :allows_access_grant, :boolean
  end
end
