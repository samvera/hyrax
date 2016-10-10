require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::NotificationService, :no_clean do
  context 'class methods' do
    subject { described_class }
    it { is_expected.to respond_to(:deliver_on_action_taken) }
  end

  let(:creating_user) { Sipity::Role.new(name: 'creating_user') }
  let(:recipient1) { Sipity::NotificationRecipient.new(recipient_strategy: 'to',
                                                       role: creating_user) }
  let(:advising) { Sipity::Role.new(name: 'advising') }
  let(:recipient2) { Sipity::NotificationRecipient.new(recipient_strategy: 'cc',
                                                       role: advising) }
  let(:notification) { Sipity::Notification.new(name: "confirmation_of_submitted_to_ulra_committee",
                                                recipients: [recipient1, recipient2]) }
  let(:notifiable_context) { Sipity::NotifiableContext.new(notification: notification) }
  let(:action) { Sipity::WorkflowAction.new(notifiable_contexts: [notifiable_context]) }
  let(:entity) { Sipity::Entity.new }
  let(:user) { User.new }

  let(:instance) { described_class.new(entity: entity,
                                       action: action,
                                       comment: "A plesant read",
                                       user: user) }

  describe "#call" do
    subject { instance.call }
    context "when the notification exists" do
      around do |example|
        class ConfirmationOfSubmittedToUlraCommittee
          def self.send_notification
          end
        end
        example.run
        Object.send(:remove_const, :ConfirmationOfSubmittedToUlraCommittee)
      end

      it "calls the notification" do
        expect(ConfirmationOfSubmittedToUlraCommittee).to receive(:send_notification)
        subject
      end
    end

    context "when the notification class doesn't have the method" do
      around do |example|
        class ConfirmationOfSubmittedToUlraCommittee; end
        example.run
        Object.send(:remove_const, :ConfirmationOfSubmittedToUlraCommittee)
      end
      it "logs an error" do
        expect(Rails.logger).to receive(:error).with("Expected 'ConfirmationOfSubmittedToUlraCommittee' to respond to 'send_notification', but it didn't, so not sending notification")
        subject
      end
    end

    context "when the notification doesn't exist" do
      it "logs an error" do
        expect(Rails.logger).to receive(:error).with("Unable to find 'ConfirmationOfSubmittedToUlraCommittee', so not sending notification")
        subject
      end
    end
  end
end
