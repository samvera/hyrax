module Hyrax
  module Workflow
    # Responsible for coordinating the behavior of an action taken within a workflow
    class WorkflowActionService
      # @param subject
      # @param action
      # @param comment
      # @param persister [Valkyrie::MetadataAdapter]
      def self.run(subject:, action:, comment: nil, persister:)
        new(subject: subject,
            action: action,
            comment: comment,
            persister: persister).run
      end

      # @param subject
      # @param action
      # @param comment
      # @param persister [Valkyrie::MetadataAdapter]
      def initialize(subject:, action:, comment:, persister:)
        @subject = subject
        @action = action
        @comment_text = comment
        @persister = persister
      end

      attr_reader :subject, :action, :comment_text, :persister

      def run
        update_sipity_workflow_state
        comment = create_sipity_comment
        handle_sipity_notifications(comment: comment)
        handle_additional_sipity_workflow_action_processing(comment: comment)
        solr_persister.save(resource: subject.work) # So that the new actions and state are written into solr.
      end

      private

        def solr_persister
          @solr_persister ||= Valkyrie::MetadataAdapter.find(:index_solr).persister
        end

        def update_sipity_workflow_state
          return true if action.resulting_workflow_state_id.blank?
          subject.entity.update!(workflow_state_id: action.resulting_workflow_state_id)
        end

        def create_sipity_comment
          return true if comment_text.blank?
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

        # Run any configured custom methods
        def handle_additional_sipity_workflow_action_processing(comment:)
          Hyrax::Workflow::ActionTakenService.handle_action_taken(
            target: subject.work,
            comment: comment,
            action: action,
            user: subject.user,
            persister: persister
          )
        end
    end
  end
end
