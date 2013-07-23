require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe IngestLocalFileJob do
  before do
    @user = FactoryGirl.find_or_create(:user)
    @generic_file = GenericFile.new
    @generic_file.apply_depositor_metadata(@user.user_key)
    @generic_file.save
    @mock_upload_directory = 'spec/mock_upload_directory'
    Dir.mkdir @mock_upload_directory unless File.exists? @mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), @mock_upload_directory)
  end
  after do
    @generic_file.delete
  end
  subject { IngestLocalFileJob.new(@generic_file.id, @mock_upload_directory, "world.png", @user.user_key) }
  
  describe "virus checking" do
    it "should run virus check" do
      Sufia::GenericFile::Actions.should_receive(:virus_check).and_return(0)
      subject.run
    end
    it "should abort if virus check fails" do
      Sufia::GenericFile::Actions.should_receive(:virus_check).and_return(1)
      expect { subject.run }.to raise_error(StandardError, /Virus checking did not pass/)
    end
  end
end