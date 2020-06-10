# frozen_string_literal: true
module Sipity
  # A bridge for defining the "contexts" in which emails are sent.
  #
  # When an object enters a new state, we want to be able to define what are
  # the emails that should be sent.
  #
  # In Sipity this could be modeled by defining a NotifiableContext for a
  # WorkflowState and Email.
  #
  # @example
  #   workflow_state = Sipity::WorkflowState.new
  #   notification = Sipity::Notification.new
  #
  #   Sipity::NotifiableContext.new(
  #     scope_for_notification: workflow_state,
  #     reason_for_notification: 'on_enter',
  #     notification: notification
  #   )
  class NotifiableContext < ActiveRecord::Base
    self.table_name = 'sipity_notifiable_contexts'
    belongs_to :scope_for_notification, polymorphic: true
    belongs_to :notification, class_name: 'Sipity::Notification'

    REASON_ACTION_IS_TAKEN = 'action_is_taken'
  end
end
