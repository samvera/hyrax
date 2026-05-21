# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # A `dry-transaction` step that moves a work's `Sipity::Entity` to the
      # new admin set's active workflow when the admin set has changed during
      # an update and both the old and new admin sets use workflow management.
      #
      # The entity's `workflow_state` is preserved by matching on state name:
      # the new workflow's state with the same name is used when one exists,
      # and the new workflow's initial state is used as a fallback (with a
      # warning) when it does not.
      #
      # The depositor's existing `EntitySpecificResponsibility` is re-created
      # against the new workflow's `depositing` role so it is not orphaned to
      # a `WorkflowRole` from the prior workflow.
      #
      # No-ops when:
      # * the admin set has not changed,
      # * the new admin set has no active workflow (the entity is left in
      #   place, pointing at the prior workflow), or
      # * the work has no `Sipity::Entity` yet (the prior admin set was not
      #   workflow-managed).
      class ApplyWorkflowOnAdminSetChange
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] object
        #
        # @return [Dry::Monads::Result]
        def call(object)
          return Success(object) unless object.respond_to?(:previous_admin_set_id)

          entity = Sipity::Entity.find_by(proxy_for_global_id: Hyrax::GlobalID(object).to_s)
          return Success(object) if entity.nil?

          new_workflow = active_workflow_for(object.admin_set_id)
          return Success(object) if new_workflow.nil?

          move_entity_to_workflow(entity: entity, new_workflow: new_workflow, object: object)
          reassign_depositor_responsibility(entity: entity, new_workflow: new_workflow, object: object)

          Success(object)
        end

        private

        def active_workflow_for(admin_set_id)
          Sipity::Workflow.find_active_workflow_for(admin_set_id: admin_set_id)
        rescue Sipity::Workflow::NoActiveWorkflowError
          nil
        end

        def move_entity_to_workflow(entity:, new_workflow:, object:)
          target_state = matching_state_on(new_workflow, entity.workflow_state_name) ||
                         fallback_initial_state(new_workflow, entity, object)
          entity.update!(workflow: new_workflow, workflow_state: target_state)
        end

        def matching_state_on(workflow, state_name)
          return nil if state_name.blank?
          workflow.workflow_states.find_by(name: state_name)
        end

        def fallback_initial_state(new_workflow, entity, object)
          Hyrax.logger.warn("Workflow state #{entity.workflow_state_name.inspect} from prior workflow " \
                            "does not exist on the new active workflow for AdministrativeSet " \
                            "#{object.admin_set_id}. Falling back to the initial state for work " \
                            "#{object.id}.")
          new_workflow.initial_workflow_state
        end

        def reassign_depositor_responsibility(entity:, new_workflow:, object:)
          depositor = ::User.find_by_user_key(object.depositor)
          return if depositor.nil?

          remove_stale_depositor_responsibility(entity: entity, new_workflow: new_workflow, depositor: depositor)

          Hyrax::Workflow::PermissionGenerator.call(agents: depositor,
                                                    entity: entity,
                                                    roles: Hyrax::RoleRegistry::DEPOSITING,
                                                    workflow: new_workflow)
        end

        def remove_stale_depositor_responsibility(entity:, new_workflow:, depositor:)
          depositor_agent = Sipity::Agent(depositor)
          entity.entity_specific_responsibilities
                .joins(:workflow_role)
                .where(agent_id: depositor_agent.id)
                .where.not(sipity_workflow_roles: { workflow_id: new_workflow.id })
                .destroy_all
        end
      end
    end
  end
end
