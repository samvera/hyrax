module CurationConcerns
  module Workflow
    # Responsible for creating database entries for the given workflow's actions
    class SipityActionsGenerator
      # @api public
      #
      # Responsible for creating database entries for the given workflow's actions
      #
      # @param workflow [Sipity::Workflow]
      # @param actions_configuration [Hash] as defined in CurationConcerns::Workflow::WorkflowSchema
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

      def call
        generate_state_diagram!
        workflow
      end

      private

        def generate_state_diagram!
          actions_configuration.each do |configuration|
            Array.wrap(configuration.fetch(:name)).each do |name|
              StateMachineGenerator.generate_from_schema(workflow: workflow, name: name, **configuration.except(:name))
            end
          end
        end
    end
  end
end
