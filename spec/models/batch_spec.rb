require 'spec_helper'

describe Batch do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:batch) { Batch.create(title: ["test collection"], creator: [user.user_key]) }

  it "should belong to testuser" do
    expect(batch.creator).to eq [user.user_key]
  end
  it "should be titled 'test collection'" do
    expect(batch.title).to eq ["test collection"]
  end
  it "should have generic_files defined" do
    expect(batch).to respond_to(:generic_files)
  end

  it "should support to_solr" do
    expect(batch.to_solr).to_not be_nil
    expect(batch.to_solr["batch__title_t"]).to be_nil
    expect(batch.to_solr["batch__creator_t"]).to be_nil
  end
  describe "find_or_create" do
    describe "when the object exists" do
      let! (:batch) { Batch.create(title: ["test collection"], creator: [user.user_key]) }
      it "should find batch instead of creating" do
        expect(Batch).to_not receive(:create)
        Batch.find_or_create(batch.id)
      end
    end
    describe "when the object does not exist" do
      it "should create" do
        expect { Batch.find("batch-123") }.to raise_error(ActiveFedora::ObjectNotFoundError)
        expect(Batch).to receive(:create).once.and_return("the batch")
        expect(Batch.find_or_create("batch-123")).to eq "the batch"
      end
    end
  end
end
