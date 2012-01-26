require 'spec_helper'
require 'noid'

describe GenericFile do
  before(:each) do 
    @file = GenericFile.new
  end 
  it "should have rightsMetadata" do
    @file.rightsMetadata.should be_instance_of Hydra::RightsMetadata
  end
  it "should have apply_depositor_metadata" do
    @file.apply_depositor_metadata('jcoyne')
    @file.rightsMetadata.edit_access.should == ['jcoyne']
  end
  it "should have a characterization datastream" do
    @file.characterization.should be_kind_of FitsDatastream
  end 
  it "should have a dc desc metadata" do
    @file.descMetadata.should be_kind_of Psu::DcDatastream
  end
  it "should have content datastream" do
    @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
    @file.content.should be_kind_of FileContentDatastream
  end
  it "should have an ARK-style identifier" do    
    # required to generate the actual pid
    @file.save
    xdigit = Noid::XDIGIT.join
    @file.pid.should match /^id:[#{xdigit}]{2}\d{2}[#{xdigit}]{2}\d{2}[#{xdigit}]$/
  end
  describe "characterize" do
    it "should run when the content datastream is created" do
      @file.expects(:characterize)
      @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @file.save
    end
  end
end
