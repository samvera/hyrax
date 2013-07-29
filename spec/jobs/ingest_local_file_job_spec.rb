require 'spec_helper'

describe IngestLocalFileJob do
  let(:user) { FactoryGirl.find_or_create(:user) }

  let (:generic_file) do 
    GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save } 
  end 

  before do
    @mock_upload_directory = 'spec/mock_upload_directory'
    Dir.mkdir @mock_upload_directory unless File.exists? @mock_upload_directory
    FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), @mock_upload_directory)
  end
  after do
    generic_file.destroy
  end
  subject { IngestLocalFileJob.new(generic_file.id, @mock_upload_directory, "world.png", user.user_key) }

  it "should have attached a file" do
    subject.run
    generic_file.reload.content.size.should == 4218
  end
  
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
