module Sipity
  # An actor can take the given action
  class WorkflowStateAction < ActiveRecord::Base
    self.table_name = 'sipity_workflow_state_actions'
    belongs_to :originating_workflow_state, class_name: 'WorkflowState'
    belongs_to :workflow_action
    has_many :workflow_state_action_permissions, dependent: :destroy
  end
end
