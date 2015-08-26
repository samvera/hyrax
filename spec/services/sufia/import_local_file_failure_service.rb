require 'spec_helper'

describe Sufia::ImportLocalFileFailureService do
  let!(:depositor) { FactoryGirl.find_or_create(:jill) }
  let!(:filename) { 'world.png' }
  let(:inbox) { depositor.mailbox.inbox }
  let(:file) do
    GenericFile.create do |file|
      file.apply_depositor_metadata(depositor)
    end
  end

  before do
    allow(GenericFile).to receive(:find).and_return(file)
    described_class.new(file.id, depositor.user_key, filename).call
  end
  describe "#call" do
    it "sends failing mail" do
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Local file ingest error') }
    end
  end
end
