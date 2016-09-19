module Sipity
  # Who can trigger this event?
  class WorkflowStateActionPermission < ActiveRecord::Base
    self.table_name = 'sipity_workflow_state_action_permissions'
    belongs_to :workflow_role
    belongs_to :workflow_state_action
  end
end
