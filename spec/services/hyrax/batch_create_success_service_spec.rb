RSpec.describe Hyrax::BatchCreateSuccessService do
  let(:depositor) { create(:user) }
  let(:inbox) { depositor.mailbox.inbox }

  describe "#call" do
    subject { described_class.new(depositor) }

    it "sends passing mail" do
      subject.call
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Passing batch create') }
      inbox.each { |msg| expect(msg.last_message.body).to eq('The batch create for ' + depositor.user_key + ' passed.') }
    end
  end
end
