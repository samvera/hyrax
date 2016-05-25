describe Sufia::ImportUrlSuccessService do
  let!(:depositor) { create(:user) }
  let(:inbox) { depositor.mailbox.inbox }
  let(:label) { 'foobarbaz' }
  let(:curation_concern) { create(:work_with_one_file, user: depositor, title: ['quuxquuux']) }
  let(:file_set) { curation_concern.file_sets.first }

  describe "#call" do
    before do
      allow(file_set).to receive(:label) { label }
      described_class.new(file_set, depositor).call
    end

    it "sends success mail" do
      expect(inbox.count).to eq(1)
      expect(inbox.first.last_message.subject).to eq('File Import')
      expect(inbox.first.last_message.body).to eq("The file (#{label}) was successfully imported and attached to quuxquuux.")
    end
  end
end
