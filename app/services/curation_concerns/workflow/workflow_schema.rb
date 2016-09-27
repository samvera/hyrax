module CurationConcerns
  module Workflow
    # Responsible for describing the JSON schema for a Workflow.
    #
    # The `work_types name` defines the name of the Sipity::Workflow.
    # The `work_types actions` defines the actions that can be taken in the given states (e.g. :from_states) by the given :roles.
    # The `work_types actions transition_to` defines the state to which we transition when the action is taken.
    # The `work_types actions notifications` defines the notifications that should be sent when the action is taken.
    #
    # @see Sipity::Workflow
    # @see Sipity::WorkflowAction
    # @see Sipity::WorkflowState
    # @see Sipity::Role
    # @see Sipity::Notification
    WorkflowSchema = Dry::Validation.Schema do
      required(:work_types).each do
        required(:name).filled(:str?) # Sipity::Workflow#name
        required(:actions).each do
          required(:name).filled(:str?) # Sipity::WorkflowAction#name
          required(:from_states).each do
            required(:names) { array? { each(:str?) } } # Sipity::WorkflowState#name
            required(:roles) { array? { each(:str?) } } # Sipity::Role#name
          end
          required(:transition_to).filled(:str?) # Sipity::WorkflowState#name
          optional(:notifications).each do
            required(:name).value(format?: /\A[a-z|_]+\Z/i) # Sipity::Notification#name
            required(:notification_type).value(included_in?: Sipity::Notification.valid_notification_types)
            required(:to) { array? { each(:str?) } }
            optional(:cc) { array? { each(:str?) } }
            optional(:bcc) { array? { each(:str?) } }
          end
        end
      end
    end
  end
end
