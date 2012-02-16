require 'spec_helper'

describe Folder do
  before do
    @user = User.create(:login => "testuser", 
                        :email => "testuser@example.com", 
                        :password => "password", 
                        :password_confirmation => "password")
    @file = GenericFile.create
    @folder = Folder.create(:title => "test collection",
                            :creator => @user.email,
                            :has_part => @file.pid)
  end
  after do
    @user.delete
    @file.delete
    @folder.delete
  end
  it "should have rightsMetadata" do
    @folder.rightsMetadata.should be_instance_of Hydra::RightsMetadata
  end
  it "should have apply_depositor_metadata" do
    @folder.apply_depositor_metadata(@user.login)
    @folder.rightsMetadata.edit_access.should == [@user.login]
  end
  it "should have dc desc metadata" do
    @folder.descMetadata.should be_kind_of ActiveFedora::DCRDFDatastream
  end
  it "should belong to testuser" do
    @folder.creator.should == [@user.email]
  end
  it "should be titled 'test collection'" do
    @folder.title.should == ["test collection"]
  end
  it "should contain one generic file" do
    @folder.should respond_to(:generic_files)
    @folder.has_part << @file
    @folder.has_part.should == [@file.pid]
    #@file.is_part_of.should == [@folder]
  end
  it "should be accessible via user object?"
end
