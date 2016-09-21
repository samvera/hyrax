module CurationConcerns
  module Actors
    class InitializeWorkflowActor < AbstractActor
      def create(attributes)
        next_actor.create(attributes) && create_workflow
      end

      private

        def create_workflow
          Sipity::Entity.create(proxy_for_global_id: curation_concern.to_global_id.to_s,
                                workflow: workflow,
                                workflow_state: starting_workflow_state)
          true
        end

        # This tells us which workflow to use.
        def workflow
          @workflow ||= Sipity::Workflow.find_by!(name: curation_concern.model_name.singular)
        end

        # This returns the initial workflow state. This is derived by finding a WorkflowState
        # that has no WorkflowActions leading to it.
        def starting_workflow_state
          action_ids = Sipity::WorkflowAction.where(workflow: workflow)
                                             .pluck(:resulting_workflow_state_id)
          relation = Sipity::WorkflowState.where(workflow: workflow)
          relation = relation.where('id NOT IN (?)', action_ids) if action_ids.present?
          relation.first!
        end
    end
  end
end
