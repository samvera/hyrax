require 'spec_helper'

describe Sufia::ImportUrlSuccessService do
  let!(:depositor) { create(:user) }
  let(:inbox) { depositor.mailbox.inbox }
  let(:label) { 'foobarbaz' }
  let(:file) do
    FileSet.create do |file|
      file.apply_depositor_metadata(depositor)
      file.label = label
    end
  end

  describe "#call" do
    before do
      described_class.new(file, depositor).call
    end

    it "sends success mail" do
      expect(inbox.count).to eq(1)
      expect(inbox.first.last_message.subject).to eq('File Import')
      expect(inbox.first.last_message.body).to eq("The file (#{label}) was successfully imported.")
    end
  end
end
