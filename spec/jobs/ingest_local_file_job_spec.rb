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
    expect(generic_file.reload.content.size).to eq(4218)
  end

  describe "virus checking" do
    it "should run virus check" do
      expect(Sufia::GenericFile::Actor).to receive(:virus_check).and_return(0)
      job.run
    end
    it "should abort if virus check fails" do
      allow(Sufia::GenericFile::Actor).to receive(:virus_check).and_raise(Sufia::VirusFoundError.new('A virus was found'))
      job.run
      expect(user.mailbox.inbox.first.subject).to eq("Local file ingest error")
    end
  end
end
