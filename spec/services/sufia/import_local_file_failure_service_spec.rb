require 'spec_helper'

describe Sufia::ImportLocalFileFailureService do
  let!(:depositor) { create(:user) }
  let!(:filename) { 'world.png' }
  let(:inbox) { depositor.mailbox.inbox }
  let(:file) do
    FileSet.create do |file|
      file.apply_depositor_metadata(depositor)
    end
  end

  before do
    allow(FileSet).to receive(:find).and_return(file)
    described_class.new(file.id, depositor, filename).call
  end
  describe "#call" do
    it "sends failing mail" do
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Local file ingest error') }
    end
  end
end
