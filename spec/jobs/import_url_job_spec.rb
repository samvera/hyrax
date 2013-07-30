require 'spec_helper'

describe ImportUrlJob do
  let(:user) { FactoryGirl.find_or_create(:user) }

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

  subject { ImportUrlJob.new(generic_file.id) }

  it "should have no content at the outset" do
    generic_file.content.size.should be_nil
  end

  it "should create a content datastream" do
    http_res = double('response')
    http_res.stub(:read_body).and_yield(File.open(File.expand_path('../../fixtures/world.png', __FILE__)).read)
    Net::HTTP.any_instance.stub(:request_get).and_yield(http_res)
    Net::HTTP.any_instance.should_receive(:request_get).with(URI(generic_file.import_url).request_uri)
    subject.run
    generic_file.reload.content.size.should == 4218
  end

  describe "virus checking" do
    it "should run virus check" do
      Sufia::GenericFile::Actions.should_receive(:virus_check).and_return(0)
      Sufia::GenericFile::Actions.should_receive(:create_content).once
      subject.run
    end
    it "should abort if virus check fails" do
      Sufia::GenericFile::Actions.should_receive(:virus_check).and_return(1)
      User.any_instance.should_receive(:send_message).with(user, 'The file (world.png) was unable to be imported because it contained a virus.', 'File Import Error')
      subject.run
    end
  end
end
