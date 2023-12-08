# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::PendingReviewNotification do
  let(:depositor) { create(:user) }
  let(:to_user) { create(:user) }
  let(:cc_user) { create(:user) }
  let(:work) do
    if Hyrax.config.disable_wings
      valkyrie_create(:monograph, title: ["Test title"], depositor: depositor.user_key)
    else
      create(:generic_work, user: depositor)
    end
  end
  let(:entity) { create(:sipity_entity, proxy_for_global_id: Hyrax::GlobalID(work).to_s) }
  let(:comment) { double("comment", comment: 'A pleasant read') }
  let(:recipients) { { 'to' => [to_user], 'cc' => [cc_user] } }
  let(:expected_klass) { Hyrax.config.disable_wings ? 'monographs' : 'generic_works' }

  before { work }
  describe ".send_notification" do
    it 'sends a message to all users except depositor' do
      expect(depositor).to receive(:send_message)
        .with(anything,
              "Test title (<a href=\"/concern/#{expected_klass}/#{work.id}\">#{work.id}</a>) "\
              "was deposited by #{depositor.user_key} and is awaiting approval A pleasant read",
              anything).exactly(3).times.and_call_original

      expect { described_class.send_notification(entity: entity, user: depositor, comment: comment, recipients: recipients) }
        .to change { depositor.mailbox.inbox.count }.by(1)
                                                    .and change { to_user.mailbox.inbox.count }.by(1)
                                                                                               .and change { cc_user.mailbox.inbox.count }.by(1)
    end
    context 'without carbon-copied users' do
      let(:recipients) { { 'to' => [to_user] } }

      it 'sends a message to the to user(s)' do
        expect(depositor).to receive(:send_message).exactly(2).times.and_call_original
        expect { described_class.send_notification(entity: entity, user: depositor, comment: comment, recipients: recipients) }
          .to change { depositor.mailbox.inbox.count }.by(1)
                                                      .and change { to_user.mailbox.inbox.count }.by(1)
      end
    end
  end
end
