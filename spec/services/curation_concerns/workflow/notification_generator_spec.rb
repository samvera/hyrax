require 'spec_helper'
module CurationConcerns
  module Workflow
    RSpec.describe NotificationGenerator do
      let(:workflow) { Sipity::Workflow.new(id: 1) }
      let(:recipients) { { to: 'creating_user', cc: 'advising', bcc: "data_observing" } }

      context '#call' do
        context 'with for reason: REASON_ACTION_IS_TAKEN' do
          let(:reason) { Sipity::NotifiableContext::REASON_ACTION_IS_TAKEN }
          it 'will generate the requisite entries' do
            workflow_action = Sipity::WorkflowAction.create!(workflow_id: workflow.id, name: 'show')
            expect do
              described_class.call(
                workflow: workflow, reason: reason, scope: 'show', notification_name: 'the_weasal', recipients: recipients,
                notification_type: 'email'
              )
            end.to change { Sipity::Notification.count }.by(1)
            .and change { Sipity::NotificationRecipient.count }.by(3)
            .and change { workflow_action.notifiable_contexts.count }.by(1)
          end
        end

        context 'with for reason: REASON_ENTERED_STATE' do
          let(:reason) { Sipity::NotifiableContext::REASON_ENTERED_STATE }
          it 'will generate the requisite entries' do
            workflow_state = Sipity::WorkflowState.create!(workflow_id: workflow.id, name: 'show')
            expect do
              described_class.call(
                workflow: workflow, reason: reason, scope: 'show', notification_name: 'the_weasal', recipients: recipients,
                notification_type: 'email'
              )
            end.to change { Sipity::Notification.count }.by(1)
            .and change { Sipity::NotificationRecipient.count }.by(3)
            .and change { workflow_state.notifiable_contexts.count }.by(1)
          end
        end
      end
    end
  end
end
