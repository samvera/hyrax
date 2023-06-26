# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::NotificationService do
  let(:creating_user) { Sipity::Role.new(name: 'creating_user') }
  let(:recipient1) do
    Sipity::NotificationRecipient.new(recipient_strategy: 'to',
                                      role: creating_user)
  end
  let(:advising) { Sipity::Role.new(name: 'advising') }
  let(:recipient2) do
    Sipity::NotificationRecipient.new(recipient_strategy: 'cc',
                                      role: advising)
  end
  let(:notification) do
    Sipity::Notification.new(name: "confirmation_of_submitted_to_ulra_committee",
                             recipients: [recipient1, recipient2])
  end
  let(:notifiable_context) { Sipity::NotifiableContext.new(notification: notification) }
  let(:action) { Sipity::WorkflowAction.new(notifiable_contexts: [notifiable_context]) }
  let(:entity) { Sipity::Entity.new }
  let(:user) { User.new }
  let(:instance) do
    described_class.new(entity: entity,
                        action: action,
                        comment: "A pleasant read",
                        user: user)
  end

  context 'class methods' do
    subject { described_class }

    it { is_expected.to respond_to(:deliver_on_action_taken) }
  end

  describe "#call" do
    subject { instance.call }

    context "when the notification exists" do
      around do |example|
        class ConfirmationOfSubmittedToUlraCommittee
          def self.send_notification; end
        end
        example.run
        Object.send(:remove_const, :ConfirmationOfSubmittedToUlraCommittee)
      end

      let(:advisors) { [instance_double(User), instance_double(User)] }
      let(:creator) { [instance_double(User)] }
      let(:advisor_rel) { double(ActiveRecord::Relation, to_ary: advisors) }
      let(:creator_rel) { double(ActiveRecord::Relation, to_ary: creator) }

      before do
        allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_users_for_entity_and_roles)
          .with(entity: entity,
                roles: advising)
          .and_return(advisor_rel)

        allow(Hyrax::Workflow::PermissionQuery).to receive(:scope_users_for_entity_and_roles)
          .with(entity: entity,
                roles: creating_user)
          .and_return(creator_rel)
      end

      it "calls the notification" do
        expect(ConfirmationOfSubmittedToUlraCommittee).to receive(:send_notification).with(hash_including(recipients: { "to" => creator, 'cc' => advisors }))
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
        expect(Hyrax.logger).to receive(:error).with("Expected 'ConfirmationOfSubmittedToUlraCommittee' to respond to 'send_notification', but it didn't, so not sending notification")
        subject
      end
    end

    context "when the notification doesn't exist" do
      it "logs an error" do
        expect(Hyrax.logger).to receive(:error).with("Unable to find 'ConfirmationOfSubmittedToUlraCommittee', so not sending notification")
        subject
      end
    end
  end
end
