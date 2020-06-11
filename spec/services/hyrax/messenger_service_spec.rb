# frozen_string_literal: true
RSpec.describe Hyrax::MessengerService do
  describe '#deliver' do
    let(:sender) { create(:user) }
    let(:recipients) { create(:user) }
    let(:body) { 'Quite an excellent message' }
    let(:subject) { 'IMPORTANT' }
    let(:other_arg) { 'Did I make it?' }

    it 'invokes Hyrax::MessengerService to deliver the message' do
      expect(sender).to receive(:send_message).with(recipients, body, subject, other_arg)
      expect(StreamNotificationsJob).to receive(:perform_later).with(recipients)
      described_class.deliver(sender, recipients, body, subject, other_arg)
    end
  end
end
