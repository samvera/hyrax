module Hyrax
  module Workflow
    # Responsible for creating database entries for the given workflow's actions
    class SipityActionsGenerator
      # @api public
      #
      # Responsible for creating database entries for the given workflow's actions
      #
      # @param [Sipity::Workflow] workflow
      # @param [Hash] actions_configuration as defined in Hyrax::Workflow::WorkflowSchema
      # @return [Sipity::Workflow]
      # @raise [Hyrax::Workflow::InvalidStateRemovalException] Trying to remove a state that is in use
      def self.call(workflow:, actions_configuration:, &block)
        new(workflow: workflow, actions_configuration: actions_configuration, &block).call
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

      # @return [Sipity::Workflow]
      # @raise [Hyrax::Workflow::InvalidStateRemovalException] Trying to remove a state that is in use
      def call
        generate_state_diagram!
        workflow
      end

      private

        def generate_state_diagram!
          # look for old states that need to be removed and validate the states can be removed.
          unused_states_to_remove = validate_states_to_be_removed

          # remove any actions that will no longer be needed by the workflow
          remove_unused_actions!

          actions_configuration.each do |configuration|
            Array.wrap(configuration.fetch(:name)).each do |name|
              StateMachineGenerator.generate_from_schema(workflow: workflow, name: name, **configuration.except(:name))
            end
          end

          # remove any states that are no longer needed by the workflow
          #  Note I am doing this after the update so nothing is still linking to the
          #       state to keep it from being deleted.
          unused_states_to_remove.each(&:destroy)
        end

        def validate_states_to_be_removed
          new_state_names = extract_new_state_names
          states_to_remove = []
          states_that_cannot_be_destroyed = []
          workflow.workflow_states.each do |state|
            next if new_state_names.include?(state.name)
            states_to_remove << state
            states_that_cannot_be_destroyed << state if state.entities.count > 0 # Choosing count so we pre-warm the query
          end
          if states_that_cannot_be_destroyed.any?
            exception_message = "Cannot delete one or more states because they have one or more entities associated with them."
            raise InvalidStateRemovalException.new(exception_message, states_that_cannot_be_destroyed)
          end
          states_to_remove
        end

        # @note Not all states are things that we tansition_to; They can be transitioned from_states as well.
        def extract_new_state_names
          (
            actions_configuration.map { |a| a.fetch(:transition_to, nil) } +
            actions_configuration.map { |a| a.fetch(:from_states, []).map { |fs| fs.fetch(:names, nil) } }
          ).flatten.compact.uniq
        end

        def remove_unused_actions!
          # clear any actions from the workflow that do not exists in the new configuration
          new_action_names = actions_configuration.map { |a| a[:name] }.flatten
          workflow.workflow_actions.each do |workflow_action|
            workflow_action.destroy unless new_action_names.include?(workflow_action.name)
          end
        end
    end
  end
end
