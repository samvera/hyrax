require 'active_support/core_ext/array/wrap'

module Hyrax
  module Workflow
    # A "power users" helper class. It builds out the permissions for a host of
    # information.
    #
    # See the specs for more on what is happening, however the general idea is
    # to encapsulate the logic of assigning :agents to the :role either for
    # the :entity or the :workflow. Then creating the given :action_names for
    # the :workflow and :workflow_state and granting permission in that
    # :workflow_state for the given :role.
    class PermissionGenerator
      def self.call(**keywords, &block)
        new(**keywords, &block).call
      end

      def initialize(roles:, workflow:, agents: [], **keywords)
        self.roles = roles
        self.workflow = workflow
        self.agents = agents
        self.entity = keywords.fetch(:entity) if keywords.key?(:entity)
        self.workflow_state = keywords.fetch(:workflow_state, false)
        self.action_names = keywords.fetch(:action_names, [])
        yield(self) if block_given?
      end

      private

        attr_accessor :workflow, :workflow_state
        attr_reader :entity, :agents, :action_names, :roles

        def agents=(input)
          @agents = Array.wrap(input).map { |agent| PowerConverter.convert_to_sipity_agent(agent) }
        end

        def action_names=(input)
          @action_names = Array.wrap(input)
        end

        def roles=(input)
          @roles = Array.wrap(input).map { |role| PowerConverter.convert_to_sipity_role(role) }
        end

        def entity=(entity)
          @entity = PowerConverter.convert_to_sipity_entity(entity)
        end

      public

      def call
        roles.each do |role|
          workflow_role = Sipity::WorkflowRole.find_or_create_by!(role: role, workflow: workflow)
          associate_workflow_role_at_entity_level(workflow_role)
          associate_workflow_role_at_workflow_level(workflow_role)
          create_action_and_permission_for_actions(workflow_role)
        end
      end

      private

        def create_action_and_permission_for_actions(workflow_role)
          action_names.each do |action_name|
            create_action_and_permission_for(action_name, workflow_role)
          end
        end

        def create_action_and_permission_for(action_name, workflow_role)
          workflow_action = Sipity::WorkflowAction.find_or_create_by!(workflow: workflow, name: action_name)
          return unless workflow_state.present?
          state_action = Sipity::WorkflowStateAction.find_or_create_by!(
            workflow_action: workflow_action, originating_workflow_state: workflow_state
          )
          Sipity::WorkflowStateActionPermission
            .find_or_create_by!(workflow_role: workflow_role, workflow_state_action: state_action)
        end

        def associate_workflow_role_at_workflow_level(workflow_role)
          return if entity
          # TODO: What if we don't have an entity? If that is the case then we want to associate the
          #   agent at the workflow level.
          agents.each { |agent| Sipity::WorkflowResponsibility.find_or_create_by!(workflow_role: workflow_role, agent: agent) }
        end

        def associate_workflow_role_at_entity_level(workflow_role)
          return unless entity
          # TODO: What if we don't have an entity? If that is the case then we want to associate the
          #   agent at the workflow level.
          agents.each do |agent|
            Sipity::EntitySpecificResponsibility.find_or_create_by!(workflow_role: workflow_role, entity: entity, agent: agent)
          end
        end
    end
  end
end
