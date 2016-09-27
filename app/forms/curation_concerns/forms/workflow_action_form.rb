module CurationConcerns
  module Forms
    class WorkflowActionForm
      include ActiveModel::Validations
      extend ActiveModel::Translation

      def initialize(current_ability:, work:, attributes: {})
        @current_ability = current_ability
        @work = work
        @name = attributes.fetch(:name, false)
        @comment = attributes.fetch(:comment, nil)
      end

      attr_reader :current_ability, :work, :name, :comment

      def save
        convert_to_sipity_objects!
        return false unless valid?
        update_sipity_workflow_state
        comment = create_sipity_comment
        handle_sipity_notifications(comment: comment)
        handle_additional_sipity_workflow_action_processing(comment: comment)
        true
      end

      validates :name, presence: true
      validate :authorized_for_processing

      def authorized_for_processing
        return true if CurationConcerns::Workflow::PermissionQuery.authorized_for_processing?(
          user: agent, entity: entity, action: sipity_workflow_action
        )
        errors.add(:base, :unauthorized)
        false
      end

      private

        def convert_to_sipity_objects!
          @entity = PowerConverter.convert(work, to: :sipity_entity)
          @agent = PowerConverter.convert(current_user, to: :sipity_agent)
          @sipity_workflow_action = PowerConverter.convert_to_sipity_action(name, scope: entity.workflow)
        end

        attr_reader :entity, :agent, :sipity_workflow_action

        delegate :current_user, to: :current_ability

        def create_sipity_comment
          return true unless comment.present?
          Sipity::Comment.create!(entity: entity, agent: agent, comment: comment)
        end

        def update_sipity_workflow_state
          return true unless sipity_workflow_action.resulting_workflow_state_id.present?
          entity.update_attribute(:workflow_state_id, sipity_workflow_action.resulting_workflow_state_id)
        end

        def handle_sipity_notifications(comment:)
          CurationConcerns::Workflow::NotificationService.deliver_on_action_taken(
            entity: entity, comment: comment, action: sipity_workflow_action, user: current_user
          )
        end

        def handle_additional_sipity_workflow_action_processing(comment:)
          CurationConcerns::Workflow::ActionTakenService.handle_action_taken(
            entity: entity, comment: comment, action: sipity_workflow_action, user: current_user
          )
        end
    end
  end
end
