module CurationConcerns
  module Workflow
    class WorkflowFactory
      # @return [TrueClass]
      def self.create(work, attributes)
        new(work, attributes).create
      end

      # @param work [#to_global_id]
      # @param attributes [Hash]
      def initialize(work, attributes)
        @work = work
        @attributes = attributes
      end

      attr_accessor :work, :attributes

      # Creates a Sipity::Entity for the work.
      # The Sipity::Entity acts as a proxy to a work within a workflow
      # @return [TrueClass]
      def create
        Sipity::Entity.create(proxy_for_global_id: work.to_global_id.to_s,
                              workflow: workflow,
                              workflow_state: starting_workflow_state)
        true
      end

      # This tells us which workflow to use. If no workflow is found with the expected name
      # then load the workflows in config/workflows/*.json and try again.
      # @return [Sipity::Workflow]
      def workflow
        @workflow ||= Sipity::Workflow.find_by(name: workflow_name) ||
                      (CurationConcerns::Workflow::WorkflowImporter.load_workflows &&
                       Sipity::Workflow.find_by!(name: workflow_name))
      end

      # You may override this method select a different workflow.
      # @return [String]
      def workflow_name
        work.model_name.singular
      end

      # This returns the initial workflow state. This is derived by finding a WorkflowState
      # that has no WorkflowActions leading to it.
      # @return [Sipity::WorkflowState]
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
