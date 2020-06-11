# frozen_string_literal: true
module Hyrax
  module Workflow
    RSpec.describe NotificationGenerator do
      let(:workflow) { create(:workflow) }
      let(:recipients) { { to: 'creating_user', cc: 'advising', bcc: "data_observing" } }

      context '#call' do
        context 'with for a workflow action' do
          let(:notification_configuration) do
            NotificationConfigurationParameter.build_from_workflow_action_configuration(
              workflow_action: 'an_action', config: recipients.merge(name: 'the_weasel', notification_type: 'email')
            )
          end

          it 'will generate the requisite entries' do
            workflow_action = Sipity::WorkflowAction.create!(workflow_id: workflow.id, name: 'an_action')
            expect do
              described_class.call(workflow: workflow, notification_configuration: notification_configuration)
            end.to change { Sipity::Notification.count }.by(1)
                                                        .and change { Sipity::NotificationRecipient.count }.by(3)
                                                                                                           .and change { workflow_action.notifiable_contexts.count }.by(1)
          end
        end
      end
    end
  end
end
