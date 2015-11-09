require 'spec_helper'

describe Sufia::UploadSetUpdateFailureService do
  let(:depositor) { FactoryGirl.find_or_create(:jill) }
  let(:batch) { UploadSet.create }

  let!(:file) do
    FileSet.new(batch: batch) do |file|
      file.apply_depositor_metadata(depositor)
    end
  end

  describe "#call" do
    subject { described_class.new(file, depositor) }

    it "sends failing mail" do
      subject.call
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Failing Upload Set Update') }
    end
  end
end
