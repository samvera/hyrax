module Hyrax
  module Workflow
    # Responsible for creating database entries for the given workflow's permissions
    class WorkflowPermissionsGenerator
      # @api public
      #
      # Responsible for creating database entries for the given workflow's permissions
      #
      # @param workflow [Sipity::Workflow]
      # @param workflow_permissions_configuration [Hash] as defined in Hyrax::Workflow::WorkflowSchema
      # @return [Sipity::Workflow]
      def self.call(workflow:, workflow_permissions_configuration:)
        new(workflow: workflow, workflow_permissions_configuration: workflow_permissions_configuration).call
      end

      def initialize(workflow:, workflow_permissions_configuration:)
        self.workflow = workflow
        self.workflow_permissions_configuration = workflow_permissions_configuration
      end

      private

        attr_accessor :workflow
        attr_reader :workflow_permissions_configuration

        def workflow_permissions_configuration=(input)
          @workflow_permissions_configuration = Array.wrap(input)
        end

      public

      def call
        find_or_create_workflow_permissions!
        workflow
      end

      private

        def find_or_create_workflow_permissions!
          # In Sipity application, Agents were assigned in the configuration file.
          # However this is something assigned via a UI component for a given role.
          default_agents = []
          workflow_permissions_configuration.each do |configuration|
            PermissionGenerator.call(agents: default_agents, roles: configuration.fetch(:role), workflow: workflow)
          end
        end
    end
  end
end
