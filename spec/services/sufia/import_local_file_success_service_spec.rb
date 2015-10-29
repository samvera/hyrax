require 'spec_helper'

describe Sufia::ImportLocalFileSuccessService do
  let!(:depositor) { FactoryGirl.find_or_create(:jill) }
  let!(:filename) { 'world.png' }
  let(:inbox) { depositor.mailbox.inbox }
  let(:file) do
    FileSet.create do |file|
      file.apply_depositor_metadata(depositor)
    end
  end

  describe '#call' do
    subject { described_class.new(file, depositor, filename) }

    it 'sends success mail' do
      subject.call
      expect(inbox.count).to eq(1)
      expect(inbox.first.last_message.subject).to eq('Local file ingest')
      expect(inbox.first.last_message.body).to eq("The file (#{filename}) was successfully deposited.")
    end

    it 'spawns a deposit event job' do
      expect(ContentDepositEventJob).to receive(:new).with(file.id, depositor.user_key).once.and_call_original
      subject.call
    end
  end
end
