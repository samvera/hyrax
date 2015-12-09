require 'spec_helper'

describe Sufia::UploadSetUpdateSuccessService do
  let(:depositor) { create(:user) }
  let(:upload_set) { UploadSet.create }
  let(:inbox) { depositor.mailbox.inbox }

  describe "#call" do
    subject { described_class.new(depositor, upload_set) }

    it "sends passing mail" do
      subject.call
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Passing Upload Set Update') }
    end
  end
end
