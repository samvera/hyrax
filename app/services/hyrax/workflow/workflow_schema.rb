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

    # If using dry-validation < 1, create a Dry::Validation::Schema for backwards-compatibility.
    # This schema should never ever change.  If you need to modify it, upgrade to dry-validation >= 1
    # and use the Dry::Validation::Contract subclass below.
    if defined? Dry::Validation::Schema
      Deprecation.warn(self, 'The Dry::Validation::Schema implemenation of Hyrax::Workflow::WorkflowSchema is deprecated. ' \
                       'Please upgrade to dry-validation >= 1 to use the Dry::Validation::Contract implementation which will be part of Hyrax 3.0')
      WorkflowSchema = Dry::Validation.Schema do
        configure do
          def self.messages
            Dry::Validation::Messages.default.merge(
              en: { errors: { constant_name?: 'must be an initialized Ruby constant' } }
            )
          end

          def constant_name?(value)
            value.constantize
            true
          rescue NameError
            false
          end
        end

        required(:workflows).each do
          required(:name).filled(:str?) # Sipity::Workflow#name
          optional(:label).filled(:str?) # Sipity::Workflow#label
          optional(:description).filled(:str?) # Sipity::Workflow#description
          optional(:allows_access_grant).filled(:bool?) # Sipity::Workflow#allows_access_grant?
          required(:actions).each do
            schema do
              required(:name).filled(:str?) # Sipity::WorkflowAction#name
              required(:from_states).each do
                schema do
                  required(:names) { array? { each(:str?) } } # Sipity::WorkflowState#name
                  required(:roles) { array? { each(:str?) } } # Sipity::Role#name
                end
              end
              optional(:transition_to).filled(:str?) # Sipity::WorkflowState#name
              optional(:notifications).each do
                schema do
                  required(:name).value(:constant_name?) # Sipity::Notification#name
                  required(:notification_type).value(included_in?: Sipity::Notification.valid_notification_types)
                  required(:to) { array? { each(:str?) } }
                  optional(:cc) { array? { each(:str?) } }
                  optional(:bcc) { array? { each(:str?) } }
                end
              end
              optional(:methods) { array? { each(:str?) } } # See it_behaves_like "a Hyrax workflow method"
            end
          end
        end
      end
    elsif defined? Dry::Validation::Contract
      # For dry-validation >= 1
      class WorkflowSchema < Dry::Validation::Contract
        class Types
          include Dry::Types()

          Constant = Types::Class.constructor do |v|
            begin
              v.constantize
            rescue NameError => _err
              v
            end
          end
        end

        # Wrap the result for backwards-compatibility. This will be removed in Hyrax 3.0.
        class ResultWrapper < SimpleDelegator
          def messages(opts = {})
            errors(opts)
          end
        end

        # Provide a class method for backwards-compatibility. This will be removed in Hyrax 3.0.
        def self.call(data)
          ResultWrapper.new(new.call(data))
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
end
