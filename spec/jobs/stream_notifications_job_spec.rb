RSpec.describe StreamNotificationsJob do
  describe '#perform' do
    context 'with zero users' do
      let(:users) { nil }

      it 'does not broadcast' do
        expect(Hyrax::NotificationsChannel).not_to receive(:broadcast_to)
        described_class.perform_now(users)
      end
    end

    context 'with a user' do
      let(:users) { create(:user) }
      let(:mailbox) { double('mailbox', unread_count: 7, label: "You've got mail!") }

      before do
        allow(UserMailbox).to receive(:new).and_return(mailbox)
      end

      it 'broadcasts to the user' do
        expect(Hyrax::NotificationsChannel).to receive(:broadcast_to)
          .once
          .with(users,
                notifications_count: 7,
                notifications_label: "You've got mail!")
        described_class.perform_now(users)
      end
    end
  end
end
