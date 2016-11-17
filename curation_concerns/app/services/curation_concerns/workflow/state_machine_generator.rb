module CurationConcerns
  module Workflow
    # Imports a single action for a workflow, including all of the adjacent states,
    # permissions and notifications
    class StateMachineGenerator
      def self.generate_from_schema(workflow:, name:, **keywords)
        new(
          workflow: workflow, action_name: name, config: keywords,
          email_generator_method_name: :schema_based_email_generator_method
        ).call
      end

      def initialize(workflow:, action_name:, config:, email_generator_method_name: :schema_based_email_generator_method)
        self.workflow = workflow
        self.action_name = action_name
        self.config = config
        self.email_generator_method_name = email_generator_method_name
      end

      private

        attr_accessor :workflow, :action_name, :config, :email_generator_method_name

        def create_workflow_action!
          @action = Sipity::WorkflowAction.find_or_create_by!(workflow: workflow, name: action_name.to_s)
        end

      public

      attr_reader :action

      def call
        create_workflow_action!

        if config.key?(:attributes)
          build_attributes(config.fetch(:attributes).stringify_keys)
        end

        # Strategy State
        config.fetch(:from_states, []).each do |entry|
          build_from_state(entry.fetch(:names), entry.fetch(:roles))
        end

        # Transitions
        if config.key?(:transition_to)
          build_transitions(config.fetch(:transition_to).to_s)
        end

        send(email_generator_method_name, workflow: workflow, config: config)

        # Methods
        if config.key?(:methods)
          build_methods(Array.wrap(config.fetch(:methods)))
        end
      end

      def build_attributes(action_attributes)
        action_attributes.delete('presentation_sequence') # TODO: remove this line when we want to support presentation_sequence
        existing_action_attributes = action.attributes.slice(*action_attributes.keys)
        unless action_attributes == existing_action_attributes
          action.update_attributes!(action_attributes)
        end
      end

      def build_transitions(name)
        transition_to_state = Sipity::WorkflowState.find_or_create_by!(workflow: workflow, name: name)
        if action.resulting_workflow_state != transition_to_state
          action.resulting_workflow_state = transition_to_state
          action.save!
        end
      end

      # @params state_names[Array]
      # @params roles [Array]
      def build_from_state(state_names, state_roles)
        Array.wrap(state_names).each do |state_name|
          workflow_state = Sipity::WorkflowState.find_or_create_by!(workflow: workflow, name: state_name.to_s)
          PermissionGenerator.call(
            actors: [],
            roles: state_roles,
            workflow_state: workflow_state,
            action_names: action_name,
            workflow: workflow
          )
        end
      end

      def build_methods(method_list)
        MethodGenerator.call(action: action, list: method_list)
      end

      def schema_based_email_generator_method(workflow:, config:)
        Array.wrap(config.fetch(:notifications, [])).each do |configuration|
          notification_configuration = NotificationConfigurationParameter.build_from_workflow_action_configuration(
            workflow_action: action_name, config: configuration
          )
          NotificationGenerator.call(workflow: workflow, notification_configuration: notification_configuration)
        end
      end
    end
  end
end
