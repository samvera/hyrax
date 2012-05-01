require 'spec_helper'

describe Batch do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @file = GenericFile.create
    @batch = Batch.create(:title => "test collection",
                          :creator => @user.login,
                          :part => @file.pid)
  end
  after(:all) do
    @user.delete
    @file.delete
    @batch.delete
  end
  it "should have rightsMetadata" do
    @batch.rightsMetadata.should be_instance_of Hydra::Datastream::RightsMetadata
  end
  it "should have dc desc metadata" do
    @batch.descMetadata.should be_kind_of BatchRdfDatastream
  end
  it "should belong to testuser" do
    @batch.creator.should == [@user.login]
  end
  it "should be titled 'test collection'" do
    @batch.title.should == ["test collection"]
  end
  it "should have generic_files defined" do
    @batch.should respond_to(:generic_files)
  end
  it "should contain one generic file" do
    @batch.part.should == [@file.pid]
  end
  it "should be able to have more than one file" do
    gf = GenericFile.create
    @batch.part << gf.pid
    @batch.save
    @batch.part.should == [@file.pid, gf.pid]
  end
  it "should support to_solr" do
    @batch.to_solr.should_not be_nil
    @batch.to_solr["batch__part_t"].should be_nil
    @batch.to_solr["batch__title_t"].should be_nil
    @batch.to_solr["batch__creator_t"].should be_nil
  end
end
