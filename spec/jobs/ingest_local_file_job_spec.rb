require 'spec_helper'

describe IngestLocalFileJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:generic_file) { create :generic_file, depositor: user }

  let(:job) { IngestLocalFileJob.new(generic_file.id, mock_upload_directory, "world.png", user.user_key) }
  let(:mock_upload_directory) { 'spec/mock_upload_directory' }

  before do
    Dir.mkdir mock_upload_directory unless File.exists? mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), mock_upload_directory)
  end

  it "should have attached a file" do
    job.run
    expect(generic_file.reload.original_file.size).to eq(4218)
  end

  describe "virus checking" do
    it "should run virus check" do
      expect(CurationConcerns::VirusDetectionService).to receive(:detect_viruses).and_return(0)
      job.run
    end
    it "should abort if virus check fails" do
      allow(CurationConcerns::VirusDetectionService).to receive(:detect_viruses).and_raise(CurationConcerns::VirusFoundError.new('A virus was found'))
      job.run
      expect(user.mailbox.inbox.first.subject).to eq("Local file ingest error")
    end
  end
end
