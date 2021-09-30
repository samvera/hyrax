# frozen_string_literal: true
module Hyrax
  module Workflow
    # Responsible for coordinating the behavior of an action taken within a workflow
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
        subject.work.try(:update_index) # So that the new actions and state are written into solr.
      end

      private

      def update_sipity_workflow_state
        return true if action.resulting_workflow_state_id.blank?
        subject.entity.update!(workflow_state_id: action.resulting_workflow_state_id)
      end

      def create_sipity_comment
        return Sipity::NullComment.new(entity: subject.entity, agent: subject.agent) if
          comment_text.blank?
        Sipity::Comment.create!(entity: subject.entity, agent: subject.agent, comment: comment_text)
      end

      def handle_sipity_notifications(comment:)
        Hyrax::Workflow::NotificationService.deliver_on_action_taken(
          entity: subject.entity,
          comment: comment,
          action: action,
          user: subject.user
        )
      end

      ##
      # Run any configured custom methods
      #
      def handle_additional_sipity_workflow_action_processing(comment:)
        Hyrax::Workflow::ActionTakenService.handle_action_taken(
          target: subject.work,
          comment: comment,
          action: action,
          user: subject.user
        )
      end
    end
  end
end
