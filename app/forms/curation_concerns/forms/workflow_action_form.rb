module CurationConcerns
  module Forms
    # TODO: Get this working
    class WorkflowActionForm
      # @api public
      #
      # @note Exposed as a convenience method and to ensure that collaborators need not worry about the sipity conversions that occur.
      def self.save(**kwargs)
        new(**kwargs).save
      end

      def initialize(current_ability:, work:, workflow_action:)
        @current_ability = current_ability
        @work = work
        @workflow_action_name = workflow_action.fetch(:name)
        @workflow_action_comment = workflow_action.fetch(:comment)
        convert_to_sipity_objects!
      end

      attr_reader :current_ability, :work, :workflow_action_name, :workflow_action_comment

      def save
        return false unless valid?
        update_sipity_workflow_state
        create_sipity_comment
        return true
      end

      def valid?
        CurationConcerns::Workflow::PermissionQuery.authorized_for_processing?(
          user: current_user, entity: work, action: workflow_action_name
        )
      end

      private

      def convert_to_sipity_objects!
      end

      delegate :current_user, to: :current_ability

      def create_sipity_comment
        Sipity::Comment.create!(
          entity: PowerConverter.convert(work, to: :sipity_entity),
          agent: PowerConverter.convert(current_user, to: :sipity_agent),
          comment: workflow_action_comment
        )
      end

      def update_sipity_workflow_state

      end
    end
  end
end
