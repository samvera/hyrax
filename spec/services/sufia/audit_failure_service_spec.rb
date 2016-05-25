describe Sufia::AuditFailureService do
  let!(:depositor) { create(:user) }
  let!(:log_date) { '2015-07-15 03:06:59' }
  let(:inbox) { depositor.mailbox.inbox }
  let(:file) do
    FileSet.create do |file|
      file.apply_depositor_metadata(depositor)
    end
  end

  before do
    allow(file).to receive(:log_date).and_return('2015-07-15 03:06:59')
    allow(file).to receive(:title).and_return('World Icon')
    allow(file.original_file).to receive(:uri).and_return("http://localhost:8983/fedora/rest/test/nv/93/5x/32/nv935x32f/files/e5b91275-aab7-4720-88d4-c153d7196c23")
  end

  describe "#call" do
    subject { described_class.new(file, depositor, log_date) }

    it "sends failing mail" do
      subject.call
      expect(inbox.count).to eq(1)
      inbox.each { |msg| expect(msg.last_message.subject).to eq('Failing Audit Run') }
    end
  end
end
