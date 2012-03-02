require 'spec_helper'

describe Folder do
  before(:all) do
    @user = User.create(:login => "testuser", 
                        :email => "testuser@example.com", 
                        :password => "password", 
                        :password_confirmation => "password")
    @file = GenericFile.create
    folder = Folder.create(:title => "test collection",
                           :creator => @user.login,
                           :part => @file.pid)
    # not sure why, but the obj returned by the prior call doesn't
    # seem to have values for title, creator, has_part
    @folder = Folder.find(folder.pid)
  end
  after(:all) do
    @user.delete
    @file.delete
    @folder.delete
  end
  it "should have rightsMetadata" do
    @folder.rightsMetadata.should be_instance_of Hydra::RightsMetadata
  end
  it "should have dc desc metadata" do
    @folder.descMetadata.should be_kind_of FolderRDFDatastream
  end
  it "should belong to testuser" do
    @folder.creator.should == [@user.email]
  end
  it "should be titled 'test collection'" do
    @folder.title.should == ["test collection"]
  end
  it "should have generic_files defined" do
    @folder.should respond_to(:generic_files)
  end
  it "should contain one generic file" do
    @folder.part.should == [@file.pid]
  end
  it "should be able to have more than one file" do
    gf = GenericFile.create
    @folder.part = @folder.part.push(gf.pid)
    @folder.save
    # TODO: should not have to do this, I don't think.
    f = Folder.find(@folder.pid)
    f.part.should include(@file.pid)
    f.part.should include(gf.pid)
  end
  it "should be accessible via file object?" 
  it "should be accessible via user object?"
end
