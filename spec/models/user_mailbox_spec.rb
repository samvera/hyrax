# frozen_string_literal: true
RSpec.describe UserMailbox do
  let(:user)         { create(:user) }
  let(:another_user) { create(:user) }

  before do
    another_user.send_message(user, "Test Message", "Test Subject")
    user.send_message(another_user, "Test Message", "Test Subject")
  end

  subject { described_class.new(user) }

  describe "#inbox" do
    subject { described_class.new(user).inbox.first.last_message }

    it "has mail" do
      expect(subject.body).to eq('Test Message')
      expect(subject.subject).to eq('Test Subject')
      expect(user.mailbox.inbox(unread: true).count).to eq(0)
    end
  end

  describe '#unread_count' do
    it 'returns the number of unread messages for a user' do
      expect { another_user.send_message(user, 'Another Test', '[subj]') }
        .to change { subject.unread_count }.from(1).to(2)
    end
  end

  describe '#label' do
    # rubocop:disable RSpec/SubjectStub
    before do
      allow(subject).to receive(:unread_count).and_return(count)
    end
    # rubocop:enable RSpec/SubjectStub

    context 'with zero unread messages' do
      let(:count) { 0 }

      it 'returns the appropriate label' do
        expect(subject.label).to eq 'You have no unread notifications'
      end
    end

    context 'with one unread message' do
      let(:count) { 1 }

      it 'returns the appropriate label' do
        expect(subject.label).to eq 'You have one unread notification'
      end
    end

    context 'with multiple unread messages' do
      let(:count) { 5 }

      it 'returns the appropriate label' do
        expect(subject.label).to eq 'You have 5 unread notifications'
      end
    end

    describe 'locales' do
      let(:count) { 3 }

      context 'when param is passed' do
        it 'returns the label in the specified locale' do
          expect(subject.label('es')).to eq 'Tienes notificaciones no leídas de 3'
        end
      end

      context 'when param is not passed' do
        before { allow(user).to receive(:preferred_locale).and_return(preferred_locale) }

        context 'when user has a preferred locale' do
          let(:preferred_locale) { 'it' }

          it 'returns the label in the user-preferred locale' do
            expect(I18n).not_to receive(:default_locale)
            expect(subject.label).to eq 'Hai notifiche non letti 3'
          end
        end

        context 'when user lacks a preferred locale' do
          let(:preferred_locale) { nil }

          it 'returns the system default locale' do
            expect(I18n).to receive(:default_locale).once.and_return('de')
            expect(subject.label).to eq 'Sie haben 3 ungelesene Benachrichtigungen'
          end
        end
      end
    end
  end

  describe "#delete_all" do
    before do
      another_user.send_message(user, 'message 2', 'subject 2')
      another_user.send_message(user, 'message 3', 'subject 3')
    end
    it "deletes all messages" do
      expect(user.mailbox.inbox.count).to eq(3)
      subject.delete_all
      expect(user.mailbox.inbox.count).to eq(0)
    end
  end

  describe "#delete" do
    let(:rec)         { another_user.send_message(user, 'message 2', 'subject 2') }
    let!(:message_id) { rec.conversation.id }

    it "deletes a message" do
      subject.destroy message_id
      expect { Mailboxer::Conversation.find(message_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "non-existing conversation" do
      let!(:message_id) { -99 }

      it "raises an error" do
        expect { subject.destroy message_id }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "deleting a message from a third party" do
      let(:curator)     { create(:user) }
      let(:message)     { another_user.send_message(curator, 'message 3', 'subject 3') }
      let!(:message_id) { message.conversation.id }

      it "does not delete the message" do
        subject.destroy message_id
        expect(subject.destroy(message_id)).to eq "You do not have privileges to delete the notification..."
        expect(Mailboxer::Conversation.find(message_id).id).to eq message_id
      end
    end
  end
end
