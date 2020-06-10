# frozen_string_literal: true
module Sipity
  # Throughout the workflow process, a processed entity may have numerous
  # states.
  class WorkflowState < ActiveRecord::Base
    self.table_name = 'sipity_workflow_states'

    belongs_to :workflow,
               class_name: 'Sipity::Workflow'

    has_many :originating_workflow_state_actions,
             dependent: :destroy,
             class_name: 'Sipity::WorkflowStateAction',
             foreign_key: :originating_workflow_state_id

    has_many :resulting_workflow_actions,
             dependent: :destroy,
             class_name: 'Sipity::WorkflowAction',
             foreign_key: :resulting_workflow_state_id

    # It is not acceptable to delete a WorkflowState if there are associated entities.
    has_many :entities, class_name: 'Sipity::Entity', dependent: :restrict_with_exception

    has_many :notifiable_contexts,
             dependent: :destroy,
             as: :scope_for_notification,
             class_name: 'Sipity::NotifiableContext'
  end
end
