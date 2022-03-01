# frozen_string_literal: true
module Hyrax
  module Workflow
    # Responsible for describing the JSON schema for a Workflow.
    #
    # The `workflows name` defines the name of the Sipity::Workflow.
    # The `workflows actions` defines the actions that can be taken in the given states (e.g. :from_states) by the given :roles.
    # The `workflows actions transition_to` defines the state to which we transition when the action is taken.
    # The `workflows actions notifications` defines the notifications that should be sent when the action is taken.
    #
    # @see Sipity::Workflow
    # @see Sipity::WorkflowAction
    # @see Sipity::WorkflowState
    # @see Sipity::Role
    # @see Sipity::Notification
    # @see Sipity::Method
    # @see ./lib/generators/hyrax/templates/workflow.json.erb
    class WorkflowSchema < Dry::Validation::Contract
      class Types
        include Dry::Types()

        Constant = Types::Class.constructor do |v|
          v.constantize
        rescue NameError => _err
          v
        end
      end

      params do
        required(:workflows).array(:hash) do
          required(:name).filled(:string) # Sipity::Workflow#name
          optional(:label).filled(:string) # Sipity::Workflow#label
          optional(:description).filled(:string) # Sipity::Workflow#description
          optional(:allows_access_grant).filled(:bool) # Sipity::Workflow#allows_access_grant?
          required(:actions).array(:hash) do
            required(:name).filled(:string) # Sipity::WorkflowAction#name
            required(:from_states).array(:hash) do
              required(:names) { array? { each(:string) } } # Sipity::WorkflowState#name
              required(:roles) { array? { each(:string) } } # Sipity::Role#name
            end
            optional(:transition_to).filled(:string) # Sipity::WorkflowState#name
            optional(:notifications).array(:hash) do
              required(:name).value(Types::Constant) # Sipity::Notification#name
              required(:notification_type).value(included_in?: Sipity::Notification.valid_notification_types)
              required(:to) { array? { each(:string) } }
              optional(:cc) { array? { each(:string) } }
              optional(:bcc) { array? { each(:string) } }
            end
          end
          optional(:methods) { array? { each(:string) } } # See it_behaves_like "a Hyrax workflow method"
        end
      end
    end
  end
end
