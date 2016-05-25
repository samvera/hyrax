describe UserMailbox do
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
