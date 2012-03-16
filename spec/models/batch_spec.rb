require 'spec_helper'

describe Batch do
  before(:all) do
    @user = User.create(:login => "testuser", 
                        :email => "testuser@example.com", 
                        :password => "password", 
                        :password_confirmation => "password")
    @file = GenericFile.create
    @batch = Batch.create(:batch_title => "test collection",
                          :batch_creator => @user.login,
                          :part => @file.pid)
  end
  after(:all) do
    @user.delete
    @file.delete
    @batch.delete
  end
  it "should have rightsMetadata" do
    @batch.rightsMetadata.should be_instance_of Hydra::RightsMetadata
  end
  it "should have dc desc metadata" do
    @batch.descMetadata.should be_kind_of BatchRDFDatastream
  end
  it "should belong to testuser" do
    @batch.batch_creator.should == [@user.email]
  end
  it "should be titled 'test collection'" do
    @batch.batch_title.should == ["test collection"]
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
    @batch.part.should include(@file.pid)
    @batch.part.should include(gf.pid)
  end
  it "should support to_solr" do
    @batch.to_solr.should_not be_nil
    @batch.to_solr.keys.select {|k| k.to_s.start_with? "part_"}.should == []
    @batch.to_solr.keys.select {|k| k.to_s.start_with? "batch_title_"}.should == []
    @batch.to_solr.keys.select {|k| k.to_s.start_with? "batch_creator_"}.should == []
  end
  it "should be accessible via file object?" 
  it "should be accessible via user object?"
end
