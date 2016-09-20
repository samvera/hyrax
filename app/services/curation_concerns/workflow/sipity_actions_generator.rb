module CurationConcerns
  module Workflow
    class SipityActionsGenerator
      # A convenience method for constructing and calling this function.
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
