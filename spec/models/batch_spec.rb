require 'spec_helper'

describe Batch, :type => :model do
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
    expect(@batch.rightsMetadata).to be_instance_of Hydra::Datastream::RightsMetadata
  end
  it "should have dc desc metadata" do
    expect(@batch.descMetadata).to be_kind_of BatchRdfDatastream
  end
  it "should belong to testuser" do
    expect(@batch.creator).to eq([@user.user_key])
  end
  it "should be titled 'test collection'" do
    expect(@batch.title).to eq(["test collection"])
  end
  it "should have generic_files defined" do
    expect(@batch).to respond_to(:generic_files)
  end
  it "should contain one generic file" do
    expect(@batch.part).to eq([@file.pid])
  end
  it "should be able to have more than one file" do
    gf = GenericFile.new
    gf.apply_depositor_metadata('mjg36')
    gf.save
    @batch.part << gf.pid
    @batch.save
    expect(@batch.part).to eq([@file.pid, gf.pid])
    gf.delete
  end
  it "should support to_solr" do
    expect(@batch.to_solr).not_to be_nil
    expect(@batch.to_solr["batch__part_t"]).to be_nil
    expect(@batch.to_solr["batch__title_t"]).to be_nil
    expect(@batch.to_solr["batch__creator_t"]).to be_nil
  end
  describe "find_or_create" do
    describe "when the object exists" do
      it "should find batch instead of creating" do
        expect(Batch).to receive(:create).never
        @b2 = Batch.find_or_create( @batch.pid)
      end
    end
    describe "when the object does not exist" do
      it "should create" do
        expect {Batch.find("batch:123")}.to raise_error(ActiveFedora::ObjectNotFoundError)
        expect(Batch).to receive(:create).once.and_return("the batch")
        @b2 = Batch.find_or_create( "batch:123")
        expect(@b2).to eq("the batch")
      end
    end
  end
end
