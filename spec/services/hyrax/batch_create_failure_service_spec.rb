RSpec.describe Hyrax::BatchCreateFailureService do
  let(:depositor) { create(:user) }
  let(:inbox) { depositor.mailbox.inbox }
  let(:messages) { ['You did a bad'] }

  describe "#call" do
    subject { described_class.new(depositor, messages) }

    it "sends failing mail" do
      subject.call
      expect(inbox.count).to eq(1)
      inbox.each do |msg|
        expect(msg.last_message.subject).to eq('Failing batch create')
        expect(msg.last_message.body).to eq('The batch create for ' + depositor.user_key + ' failed: ' + messages.first)
      end
    end
  end
end
