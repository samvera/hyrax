module CurationConcerns
  module Workflow
    class WorkflowActionService
      def self.run(subject:, action:, comment: nil)
        new(subject: subject, action: action, comment: comment).run
      end

      def initialize(subject:, action:, comment:)
        @subject = subject
        @action = action
        @comment_text = comment
      end

      attr_reader :subject, :action, :comment_text

      def run
        update_sipity_workflow_state
        comment = create_sipity_comment
        handle_sipity_notifications(comment: comment)
        handle_additional_sipity_workflow_action_processing(comment: comment)
        subject.work.update_index # So that the new actions and state are written into solr.
      end

      protected

        def update_sipity_workflow_state
          return true unless action.resulting_workflow_state_id.present?
          subject.entity.update_attribute(:workflow_state_id, action.resulting_workflow_state_id)
        end

        def create_sipity_comment
          return true unless comment_text.present?
          Sipity::Comment.create!(entity: subject.entity, agent: subject.agent, comment: comment_text)
        end

        def handle_sipity_notifications(comment:)
          CurationConcerns::Workflow::NotificationService.deliver_on_action_taken(
            entity: subject.entity,
            comment: comment,
            action: action,
            user: subject.user
          )
        end

        # Run any configured custom methods
        def handle_additional_sipity_workflow_action_processing(comment:)
          CurationConcerns::Workflow::ActionTakenService.handle_action_taken(
            entity: subject.entity,
            comment: comment,
            action: action,
            user: subject.user
          )
        end
    end
  end
end
