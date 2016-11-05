module CurationConcerns
  module Workflow
    class WorkflowFactory
      class_attribute :workflow_strategy
      self.workflow_strategy = DefaultWorkflowStrategy

      # @param work [#to_global_id]
      # @param attributes [Hash]
      # @param strategy [#name] strategy for finding which workflow to use. Defaults to an instance of WorkflowByModelNameStrategy
      # @return [TrueClass]
      def self.create(work, attributes, user, strategy = nil)
        strategy ||= workflow_strategy.new(work, attributes)
        new(work, attributes, user, strategy).create
      end

      # @param work [#to_global_id]
      # @param attributes [Hash]
      # @param strategy [#name] strategy for finding which workflow to use
      def initialize(work, attributes, user, strategy)
        @work = work
        @attributes = attributes
        @user = user
        @strategy = strategy
      end

      attr_reader :work, :attributes, :user, :strategy
      private :work, :attributes, :strategy

      # Creates a Sipity::Entity for the work.
      # The Sipity::Entity acts as a proxy to a work within a workflow
      # @return [TrueClass]
      def create
        Sipity::Entity.create!(proxy_for_global_id: work.to_global_id.to_s,
                               workflow: workflow,
                               workflow_state: nil)

        subject = WorkflowActionInfo.new(work, user)
        Workflow::WorkflowActionService.run(subject: subject,
                                            action: find_deposit_action)
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

      # Find an action that has no starting state. This is the deposit action.
      # # @return [Sipity::WorkflowAction]
      def find_deposit_action
        actions_that_lead_to_states = Sipity::WorkflowStateAction.all.pluck(:workflow_action_id)
        relation = Sipity::WorkflowAction.where(workflow: workflow)
        relation = relation.where('id NOT IN (?)', actions_that_lead_to_states) if actions_that_lead_to_states.any?
        relation.first!
      end
    end
  end
end
