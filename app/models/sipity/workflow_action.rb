# frozen_string_literal: true
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

    # Not all workflow actions will change state. For example, leaving a comment
    # is an action, but likely not one to advance the state. Whereas, remove from
    # public view is something that would likely advance the state.
    belongs_to :resulting_workflow_state,
               optional: true,
               class_name: 'Sipity::WorkflowState'

    # In what states can this (eg. self) action be taken
    has_many :workflow_state_actions, dependent: :destroy, class_name: 'Sipity::WorkflowStateAction'

    # These are arbitrary "lambdas" that you can call when the action is taken
    #   * Need to send an email?
    #   * Need to publish a WEBHOOK callback?
    #   * Need to update the ACLs for the record?
    has_many :triggered_methods, dependent: :destroy, class_name: 'Sipity::Method'

    has_many :notifiable_contexts,
             dependent: :destroy,
             as: :scope_for_notification,
             class_name: 'Sipity::NotifiableContext'

    ##
    # @param [Object] input
    # @return [String]
    def self.name_for(input, &block)
      result = case input
               when String, Symbol
                 input.to_s.sub(/[\?\!]\Z/, '')
               when Sipity::WorkflowAction
                 input.name
               end
      Sipity.handle_conversion(input, result, :to_sipity_action_name, &block)
    end
  end
end
