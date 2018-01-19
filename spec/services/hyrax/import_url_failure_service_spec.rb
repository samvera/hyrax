
RSpec.describe Hyrax::ImportUrlFailureService do
  let!(:depositor) { create(:user) }
  let(:inbox) { depositor.mailbox.inbox }
  let(:file_set) do
    create_for_repository(:file_set, user: depositor, import_url: 'http://example.com/image.png')
  end

  describe "#call" do
    before do
      described_class.new(file_set, depositor).call
    end

    it "sends failing mail" do
      expect(inbox.count).to eq(1)
      expect(inbox.first.last_message.subject).to eq('File Import Error')
    end
  end
end
