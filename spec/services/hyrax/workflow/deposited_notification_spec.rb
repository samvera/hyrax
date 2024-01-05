# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::DepositedNotification do
  let(:approver) { FactoryBot.create(:user) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:to_user) { FactoryBot.create(:user) }
  let(:cc_user) { FactoryBot.create(:user) }
  let(:work) do
    if Hyrax.config.disable_wings
      valkyrie_create(:monograph, title: ["Test title"], depositor: depositor.user_key)
    else
      create(:work, user: depositor)
    end
  end
  let(:entity) { FactoryBot.create(:sipity_entity, proxy_for: work) }
  let(:comment) { double("comment", comment: 'A pleasant read') }
  let(:recipients) { { 'to' => [to_user], 'cc' => [cc_user] } }
  let(:expected_class) { Hyrax.config.disable_wings ? 'monographs' : 'generic_works' }

  describe ".send_notification" do
    it 'sends a message to all users' do # rubocop:disable RSpec/ExampleLength
      expect(approver)
        .to receive(:send_message)
        .with(anything,
              "Test title (<a href=\"/concern/#{expected_class}/#{work.id}\">#{work.id}</a>) " \
              "was approved by #{approver.user_key}. A pleasant read",
              anything)
        .exactly(3)
        .times
        .and_call_original

      expect { described_class.send_notification(entity: entity, user: approver, comment: comment, recipients: recipients) }
        .to change { depositor.mailbox.inbox.count }
        .by(1)
        .and change { to_user.mailbox.inbox.count }
        .by(1)
        .and change { cc_user.mailbox.inbox.count }
        .by(1)
    end

    context 'without carbon-copied users' do
      let(:recipients) { { 'to' => [to_user] } }

      it 'sends a message to the to user(s)' do
        expect(approver)
          .to receive(:send_message)
          .exactly(2)
          .times.and_call_original

        expect { described_class.send_notification(entity: entity, user: approver, comment: comment, recipients: recipients) }
          .to change { depositor.mailbox.inbox.count }
          .by(1)
          .and change { to_user.mailbox.inbox.count }
          .by(1)
      end
    end
  end
end
