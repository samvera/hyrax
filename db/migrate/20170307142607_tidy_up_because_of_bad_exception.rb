class TidyUpBecauseOfBadException < ActiveRecord::Migration[4.2]
  def change
    if Hyrax::PermissionTemplate.column_names.include?('workflow_id')
      Hyrax::PermissionTemplate.all.each do |permission_template|
        workflow_id = permission_template.workflow_id
        next unless workflow_id
        Sipity::Workflow.find(workflow_id).update(active: true)
      end

      remove_column Hyrax::PermissionTemplate.table_name, :workflow_id
    end
  end
end
