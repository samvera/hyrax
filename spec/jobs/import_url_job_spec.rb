require 'spec_helper'

describe ImportUrlJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:generic_file) do
    GenericFile.new.tap do |f|
      f.import_url = "http://example.org/world.png"
      f.apply_depositor_metadata(user.user_key)
      f.save
    end
  end

  after do
    generic_file.destroy
  end

  subject(:job) { ImportUrlJob.new(generic_file.id) }

  it "should have no content at the outset" do
    generic_file.content.size.should be_nil
  end

  it "should create a content datastream" do
    http_res = double('response')
    http_res.stub(:start).and_yield
    http_res.stub(:read_body).and_yield(File.open(File.expand_path('../../fixtures/world.png', __FILE__)).read)
    Net::HTTP.any_instance.stub(:request_get).and_yield(http_res)
    Net::HTTP.any_instance.should_receive(:request_get).with(URI(generic_file.import_url).request_uri)
    job.run
    generic_file.reload.content.size.should == 4218
  end

  describe "virus checking" do
    it "should run virus check" do
      expect(Sufia::GenericFile::Actions).to receive(:virus_check).twice.and_return(0)
      job.run
    end
    it "should abort if virus check fails" do
      Sufia::GenericFile::Actions.stub(:virus_check).and_raise(Sufia::VirusFoundError.new('A virus was found'))
      job.run
      expect(user.mailbox.inbox.first.subject).to eq("File Import Error")
    end
  end
end
