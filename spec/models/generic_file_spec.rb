require 'spec_helper'


describe GenericFile do
  it "should have rightsMetadata" do
    GenericFile.new.rightsMetadata.should be_instance_of Hydra::RightsMetadata
  end
  it "should have apply_depositor_metadata" do
    file = GenericFile.new
    file.apply_depositor_metadata('jcoyne')
    file.rightsMetadata.edit_access.should == ['jcoyne']
  end
  it "should have a characterization datastream" do
    file = GenericFile.new
    file.characterization.should be_kind_of FitsDatastream
  end 
end
