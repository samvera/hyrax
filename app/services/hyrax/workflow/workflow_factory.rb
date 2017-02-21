module Hyrax
  module Workflow
    # Responsible for stitching a work into it's workflow and granting permissions accordingly
    class WorkflowFactory
      # @api public
      #
      # @param work [#to_global_id]
      # @param attributes [Hash]
      # @param user [User]
      # @return [TrueClass]
      def self.create(work, attributes, user)
        new(work, attributes, user).create
      end

      # @param work [#to_global_id]
      # @param user [User]
      # @param attributes [Hash]
      def initialize(work, attributes, user)
        @work = work
        @attributes = attributes
        @user = user
      end

      attr_reader :work, :attributes, :user
      private :work, :attributes

      # Creates a Sipity::Entity for the work.
      # The Sipity::Entity acts as a proxy to a work within a workflow
      # @return [TrueClass]
      def create
        Sipity::Entity.create!(proxy_for_global_id: work.to_global_id.to_s,
                               workflow: active_workflow,
                               workflow_state: nil)

        subject = WorkflowActionInfo.new(work, user)
        Workflow::WorkflowActionService.run(subject: subject,
                                            action: find_deposit_action)
        true
      end

      delegate :active_workflow, to: :work

      # Find an action that has no starting state. This is the deposit action.
      # # @return [Sipity::WorkflowAction]
      def find_deposit_action
        actions_that_lead_to_states = Sipity::WorkflowStateAction.all.pluck(:workflow_action_id)
        relation = Sipity::WorkflowAction.where(workflow: active_workflow)
        relation = relation.where('id NOT IN (?)', actions_that_lead_to_states) if actions_that_lead_to_states.any?
        relation.first!
      end
    end
  end
end
