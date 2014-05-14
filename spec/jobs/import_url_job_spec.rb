require 'spec_helper'

describe ImportUrlJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:file_path) { '/world.png' }

  let(:generic_file) do
    GenericFile.new.tap do |f|
      f.import_url = "http://example.org#{file_path}"
      f.apply_depositor_metadata(user.user_key)
      f.save
    end
  end

  let(:mock_response) do
    double('response').tap do |http_res|
      allow(http_res).to receive(:start).and_yield
       allow(http_res).to receive(:read_body).and_yield(File.open(File.expand_path('../../fixtures/world.png', __FILE__)).read)
    end
  end

  before do
    allow(Sufia.queue).to receive(:push) # don't run characterization or event jobs
  end

  after do
    generic_file.destroy
  end

  subject(:job) { ImportUrlJob.new(generic_file.id) }

  it "should have no content at the outset" do
    generic_file.content.size.should be_nil
  end

  it "should create a content datastream" do
    Net::HTTP.any_instance.should_receive(:request_get).with(file_path).and_yield(mock_response)
    job.run
    generic_file.reload.content.size.should == 4218
  end

  describe "virus checking" do
    it "should run virus check" do
      expect(Sufia::GenericFile::Actions).to receive(:virus_check).and_return(false)
      job.run
    end

    it "should abort if virus check fails" do
      Sufia::GenericFile::Actions.stub(:virus_check).and_raise(Sufia::VirusFoundError.new('A virus was found'))
      job.run
      expect(user.mailbox.inbox.first.subject).to eq("File Import Error")
    end
  end
end
