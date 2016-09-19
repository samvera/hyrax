module Sipity
  # Responsible for capturing a :comment made by a given :actor on a given
  # :entity at a given :originating_workflow_state as part of a given
  # :originating_workflow_action.
  #
  # A :stale comment is a comment that is not relevant based on processing
  # that has happened.
  #
  # @example
  #   As a graduate student that has had multiple changes requested by an advisor
  #   I want to see my advisors latest comments (and not previous comments from a previous requested change)
  #   So that I can see the immediate thing I need to work on
  class Comment < ActiveRecord::Base
    self.table_name = 'sipity_comments'

    belongs_to :agent, class_name: 'Sipity::Agent'
    belongs_to :entity, class_name: 'Sipity::Entity'
    belongs_to :originating_workflow_action, class_name: 'Sipity::WorkflowAction'
    belongs_to :originating_workflow_state, class_name: 'Sipity::WorkflowState'

    def name_of_commentor
      agent.proxy_for.name
    end
  end
end
