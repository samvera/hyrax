module Sipity
  # A named thing that happens within the bounds of a :workflow.
  #
  # When a Sipity::WorkflowAction is taken, it may:
  # * Advance the state to a new Sipity::WorkflowState (as defined by
  #   the :resulting_workflow_state relation)
  # * Deliver one or more notifications (as defined by the
  #   :notifiable_contexts relation)
  #
  # @see Hyrax::Forms::WorkflowActionForm
  class WorkflowAction < ActiveRecord::Base
    self.table_name = 'sipity_workflow_actions'

    belongs_to :workflow, class_name: 'Sipity::Workflow'
    belongs_to :resulting_workflow_state,
               optional: true,
               class_name: 'Sipity::WorkflowState'

    has_many :workflow_state_actions, dependent: :destroy, class_name: 'Sipity::WorkflowStateAction'
    has_many :triggered_methods, dependent: :destroy, class_name: 'Sipity::Method'

    has_many :notifiable_contexts,
             dependent: :destroy,
             as: :scope_for_notification,
             class_name: 'Sipity::NotifiableContext'
  end
end
