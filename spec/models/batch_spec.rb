require 'spec_helper'

describe Batch do
  before(:all) do
    @user = FactoryGirl.find_or_create(:jill)
    @file = GenericFile.new
    @file.apply_depositor_metadata('mjg36')
    @file.save
    @batch = Batch.create(title: ["test collection"],
                          creator: @user.user_key,
                          part: @file.pid)
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
    @batch.creator.should == [@user.user_key]
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
    gf = GenericFile.new
    gf.apply_depositor_metadata('mjg36')
    gf.save
    @batch.part << gf.pid
    @batch.save
    @batch.part.should == [@file.pid, gf.pid]
    gf.delete
  end
  it "should support to_solr" do
    @batch.to_solr.should_not be_nil
    @batch.to_solr["batch__part_t"].should be_nil
    @batch.to_solr["batch__title_t"].should be_nil
    @batch.to_solr["batch__creator_t"].should be_nil
  end
  describe "find_or_create" do
    describe "when the object exists" do
      it "should find batch instead of creating" do
        Batch.should_receive(:create).never
        @b2 = Batch.find_or_create( @batch.pid)
      end
    end
    describe "when the object does not exist" do
      it "should create" do
        lambda {Batch.find("batch:123")}.should raise_error(ActiveFedora::ObjectNotFoundError)
        Batch.should_receive(:create).once.and_return("the batch")
        @b2 = Batch.find_or_create( "batch:123")
        @b2.should == "the batch"
      end
    end
  end
end
