require 'spec_helper'

describe UploadSet do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:upload_set) { described_class.create(title: ["test collection"], creator: [user.user_key]) }
  subject { upload_set }

  it "has dc metadata" do
    expect(subject.creator).to eq [user.user_key]
    expect(subject.title).to eq ["test collection"]
  end

  it "responds to .generic_files" do
    expect(subject).to respond_to(:generic_files)
  end

  it "supports to_solr" do
    expect(subject.to_solr).to_not be_nil
    expect(subject.to_solr["upload_set__title_t"]).to be_nil
    expect(subject.to_solr["upload_set__creator_t"]).to be_nil
  end

  describe "find_or_create" do
    describe "when the object exists" do
      let!(:upload_set) { described_class.create(title: ["test collection"], creator: [user.user_key]) }
      it "finds upload_set instead of creating" do
        expect(described_class).to_not receive(:create)
        described_class.find_or_create(subject.id)
      end
    end
    describe "when the object does not exist" do
      it "creates a new Batch" do
        expect { described_class.find("upload_set-123") }.to raise_error(ActiveFedora::ObjectNotFoundError)
        expect(described_class).to receive(:create).once.and_return("the upload_set")
        expect(described_class.find_or_create("upload_set-123")).to eq "the upload_set"
      end
    end
  end
end
