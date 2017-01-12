module Hyrax
  module Workflow
    # Responsible for creating database entries for the given workflow's actions
    class SipityActionsGenerator
      # @api public
      #
      # Responsible for creating database entries for the given workflow's actions
      #
      # @param workflow [Sipity::Workflow]
      # @param actions_configuration [Hash] as defined in Hyrax::Workflow::WorkflowSchema
      # @return [Sipity::Workflow]
      def self.call(**keywords, &block)
        new(**keywords, &block).call
      end

      def initialize(workflow:, actions_configuration:)
        self.workflow = workflow
        self.actions_configuration = actions_configuration
      end

      private

        attr_accessor :workflow

        attr_reader :actions_configuration

        def actions_configuration=(input)
          @actions_configuration = Array.wrap(input)
        end

      public

      # @raises [Hyrax::Workflow::InvalidStateRemovalException] Trying to remove a state that is in use
      def call
        generate_state_diagram!
        workflow
      end

      private

        def generate_state_diagram!
          # look for old states that need to be removed and validate the states can be removed.
          removed_states = validate_states_to_be_removed

          # remove any actions that will no longer be needed by the workflow
          remove_unused_actions

          actions_configuration.each do |configuration|
            Array.wrap(configuration.fetch(:name)).each do |name|
              StateMachineGenerator.generate_from_schema(workflow: workflow, name: name, **configuration.except(:name))
            end
          end

          # remove any states that are no longer needed by the workflow
          #  Note I am doing this after the update so nothing is still linking to the
          #       state to keep it from being deleted.
          removed_states.each(&:delete)
        end

        def validate_states_to_be_removed
          new_states = actions_configuration.map { |a| a[:transition_to] }
          removed_states = workflow.workflow_states.reject { |state| new_states.include?(state.name) }
          removed_states.each do |state|
            # a state  must have been removed, we should remove it only if there is not entities currently in that state
            raise InvalidStateRemovalException.new("can not delete a state with entites", state) if state.entities.count > 0
          end
          removed_states
        end

        def remove_unused_actions
          # clear any actions from the workflow that do not exists in the new configuration
          new_actions = actions_configuration.map { |a| a[:name] }
          remove_actions = workflow.workflow_actions.reject { |action| new_actions.include?(action.name) }
          remove_actions.each(&:delete)
        end
    end
  end
end
