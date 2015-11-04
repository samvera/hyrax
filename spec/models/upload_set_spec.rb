require 'spec_helper'

describe UploadSet do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:batch) { described_class.create(title: ["test collection"], creator: [user.user_key]) }

  it "belongs to testuser" do
    expect(batch.creator).to eq [user.user_key]
  end
  it "is titled 'test collection'" do
    expect(batch.title).to eq ["test collection"]
  end
  it "has file_sets defined" do
    expect(batch).to respond_to(:file_sets)
  end

  it "supports to_solr" do
    expect(batch.to_solr).to_not be_nil
    expect(batch.to_solr["batch__title_t"]).to be_nil
    expect(batch.to_solr["batch__creator_t"]).to be_nil
  end
  describe "find_or_create" do
    describe "when the object exists" do
      let!(:batch) { described_class.create(title: ["test collection"], creator: [user.user_key]) }
      it "finds batch instead of creating" do
        expect(described_class).to_not receive(:create)
        described_class.find_or_create(batch.id)
      end
    end
    describe "when the object does not exist" do
      it "creates" do
        expect { described_class.find("batch-123") }.to raise_error(ActiveFedora::ObjectNotFoundError)
        expect(described_class).to receive(:create).once.and_return("the batch")
        expect(described_class.find_or_create("batch-123")).to eq "the batch"
      end
    end
  end
end
