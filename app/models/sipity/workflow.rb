module Sipity
  # A named workflow for processing an entity. Originally I had thought of
  # calling this a Type, but once I extracted the Processing submodule,
  # type felt to much of a noun, not conveying potentiality. Workflow
  # conveys "things will happen" because of this.
  class Workflow < ActiveRecord::Base
    self.table_name = 'sipity_workflows'

    has_many :entities, dependent: :destroy, class_name: 'Sipity::Entity'
    has_many :workflow_states, dependent: :destroy, class_name: 'Sipity::WorkflowState'
    has_many :workflow_actions, dependent: :destroy, class_name: 'Sipity::WorkflowAction'
    has_many :workflow_roles, dependent: :destroy, class_name: 'Sipity::WorkflowRole'

    DEFAULT_INITIAL_WORKFLOW_STATE = 'new'.freeze
    def initial_workflow_state
      workflow_states.find_or_create_by!(name: DEFAULT_INITIAL_WORKFLOW_STATE)
    end
  end
end
