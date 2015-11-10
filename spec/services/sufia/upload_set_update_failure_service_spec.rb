require 'spec_helper'

describe Sufia::UploadSetUpdateFailureService do
  let(:depositor) { create(:user) }
  let(:upload_set) { UploadSet.create }
  let(:inbox) { depositor.mailbox.inbox }

  let!(:file) do
    FileSet.new(upload_set: upload_set) do |file|
      file.apply_depositor_metadata(depositor)
    end
  end

  describe "#call" do
    subject { described_class.new(file, depositor, upload_set.id) }

    it "sends failing mail" do
      subject.call
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Failing Upload Set Update') }
    end
  end
end
