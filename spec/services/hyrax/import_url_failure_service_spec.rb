# frozen_string_literal: true

RSpec.describe Hyrax::ImportUrlFailureService do
  let!(:depositor) { create(:user) }
  let(:inbox) { depositor.mailbox.inbox }
  let(:file) do
    create(:file_set, user: depositor)
  end

  before do
    allow(file.errors).to receive(:full_messages).and_return(['huge mistake'])
  end

  describe "#call" do
    before do
      described_class.new(file, depositor).call
    end

    it "sends failing mail" do
      expect(inbox.count).to eq(1)
      expect(inbox.first.last_message.subject).to eq('File Import Error')
    end
  end
end
