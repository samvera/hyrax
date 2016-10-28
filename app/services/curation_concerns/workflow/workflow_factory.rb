module CurationConcerns
  module Workflow
    class WorkflowFactory
      class_attribute :workflow_strategy
      self.workflow_strategy = DefaultWorkflowStrategy

      # @param work [#to_global_id]
      # @param attributes [Hash]
      # @param strategy [#name] strategy for finding which workflow to use. Defaults to an instance of WorkflowByModelNameStrategy
      # @return [TrueClass]
      def self.create(work, attributes, strategy = nil)
        strategy ||= workflow_strategy.new(work, attributes)
        new(work, attributes, strategy).create
      end

      # @param work [#to_global_id]
      # @param attributes [Hash]
      # @param strategy [#name] strategy for finding which workflow to use
      def initialize(work, attributes, strategy)
        @work = work
        @attributes = attributes
        @strategy = strategy
      end

      attr_reader :work, :attributes, :strategy
      private :work, :attributes, :strategy

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

      delegate :workflow_name, to: :strategy

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
