# frozen_string_literal: true
module Sipity
  # An actor can take the given action
  class WorkflowStateAction < ActiveRecord::Base
    self.table_name = 'sipity_workflow_state_actions'
    belongs_to :originating_workflow_state, class_name: 'Sipity::WorkflowState'
    belongs_to :workflow_action, class_name: 'Sipity::WorkflowAction'
    has_many :workflow_state_action_permissions, dependent: :destroy, class_name: 'Sipity::WorkflowStateActionPermission'
  end
end
