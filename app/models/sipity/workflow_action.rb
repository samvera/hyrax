module Sipity
  # A named thing that "happens" to an entity.
  class WorkflowAction < ActiveRecord::Base
    self.table_name = 'sipity_workflow_actions'

    belongs_to :workflow, class_name: 'Sipity::Workflow'
    belongs_to :resulting_workflow_state, class_name: 'Sipity::WorkflowState'

    has_many :workflow_state_actions, dependent: :destroy, class_name: 'Sipity::WorkflowStateAction'

    has_many :notifiable_contexts,
             dependent: :destroy,
             as: :scope_for_notification,
             class_name: 'Sipity::NotifiableContext'

    has_many :comments,
             foreign_key: :originating_workflow_action_id,
             dependent: :destroy,
             class_name: 'Sipity::Comment'
  end
end
