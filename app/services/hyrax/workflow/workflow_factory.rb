# frozen_string_literal: true
module Hyrax
  module Workflow
    # Responsible for:
    #
    # * Creating a Sipity::Entity (aka a database proxy for the given work)
    # * Assigning specific roles to the Sipity::Entity (but not the workflow)
    # * Running the deposit_action
    #
    # @see Sipity:Entity
    # @see Hyrax::Workflow::WorkflowActionService
    # @see Hyrax::Workflow::PermissionGenerator
    # @see Hyrax::RoleRegistry
    class WorkflowFactory
      class_attribute :depositing_role
      self.depositing_role = Hyrax::RoleRegistry::DEPOSITING
      # @api public
      #
      # @param work [#to_global_id]
      # @param attributes [Hash]
      # @param user [User]
      # @return [TrueClass]
      def self.create(work, attributes, user)
        new(work, attributes, user).create
      end

      # @param work [#to_global_id, #admin_set_id]
      # @param user [User]
      # @param attributes [Hash]
      def initialize(work, attributes, user)
        @work = work
        @attributes = attributes
        @user = user
      end

      attr_reader :work, :attributes, :user
      private :work, :attributes, :user

      # Creates a Sipity::Entity for the work.
      # The Sipity::Entity acts as a proxy to a work within a workflow
      # @return [TrueClass]
      def create
        entity = create_workflow_entity!
        assign_specific_roles_to(entity: entity)
        run_workflow_action!
        true
      end

      private

      def create_workflow_entity!
        Sipity::Entity.create!(proxy_for_global_id: Hyrax::GlobalID(work).to_s,
                               workflow: workflow_for(work),
                               workflow_state: nil)
      end

      def assign_specific_roles_to(entity:)
        Hyrax::Workflow::PermissionGenerator.call(agents: user,
                                                  entity: entity,
                                                  roles: depositing_role,
                                                  workflow: workflow_for(work))
      end

      def run_workflow_action!
        subject = WorkflowActionInfo.new(work, user)
        Workflow::WorkflowActionService.run(subject: subject,
                                            action: find_deposit_action)
      end

      # Find an action that has no starting state. This is the deposit action.
      # # @return [Sipity::WorkflowAction]
      def find_deposit_action
        actions_that_lead_to_states = Sipity::WorkflowStateAction.all.pluck(:workflow_action_id)
        relation = Sipity::WorkflowAction.where(workflow: workflow_for(work))
        relation = relation.where('id NOT IN (?)', actions_that_lead_to_states) if actions_that_lead_to_states.any?
        relation.first!
      end

      def workflow_for(work)
        Sipity::Workflow.find_active_workflow_for(admin_set_id: work.admin_set_id)
      end
    end
  end
end
