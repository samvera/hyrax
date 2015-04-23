require 'spec_helper'

describe Collection do
  let(:reloaded_subject) { Collection.find(subject.id) }

  before do
    subject.title = 'A title'
  end

  it 'can be part of a collection' do
    expect(subject.can_be_member_of_collection?(double)).to be true
  end

  it 'can contain another collection' do
    another_collection = FactoryGirl.create(:collection)
    subject.members << another_collection
    expect(subject.members).to eq [another_collection]
  end

  it 'updates solr with ids of its parent collections' do
    another_collection = FactoryGirl.create(:collection)
    another_collection.members << subject
    another_collection.save
    expect(subject.reload.to_solr[Solrizer.solr_name(:collection)]).to eq [another_collection.id]
  end

  it 'cannot contain itself' do
    subject.members << subject
    subject.save
    expect(reloaded_subject.members).to eq []
  end

  describe "when visibility is private" do
    it "should not be open_access?" do
      expect(subject).to_not be_open_access
    end
    it "should not be authenticated_only_access?" do
      expect(subject).to_not be_authenticated_only_access
    end
    it "should not be private_access?" do
      expect(subject).to be_private_access
    end
  end

  describe "visibility" do
    it "should have visibility accessor" do
      expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    it "should have visibility writer" do
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(subject).to be_open_access
    end
  end

  describe "to_solr" do
    before do
      allow(subject).to receive(:id).and_return('sufia:test123')
    end

    let(:solr_doc) {subject.to_solr}

    it "should have required fields" do
      expect(solr_doc['generic_type_sim']).to eq ['Collection']
    end

  end

  describe '#human_readable_type' do
    it "indicates collection" do
      expect(subject.human_readable_type).to eq 'Collection'
    end
  end

  describe '#add_member' do
    it 'adds the member to the collection and returns true' do
      work = FactoryGirl.create(:generic_work)
      expect(subject.add_member(work)).to be true
      expect(reloaded_subject.members).to eq [work]

      work.reload
      expect(work.collections).to eq [subject]
      expect(work.to_solr["collection_sim"]).to eq [subject.id]
    end

    it 'returns nil if there is nothing to add' do
      expect(subject.add_member(nil)).to be_nil
    end

    it 'returns false if it failed to save' do
      subject.save
      work = FactoryGirl.create(:generic_work)
      allow(subject).to receive(:save).and_return(false)
      expect(subject.add_member(work)).to be false
      expect(reloaded_subject.members).to eq []
    end
  end

  describe '#members.delete' do
    it 'removes the member from the collection and returns true' do
      work = FactoryGirl.create(:generic_work)
      subject.members << work
      expect(subject.members).to eq [work]
      subject.save

      work.reload
      expect(work.collections).to eq [subject]
      expect(work.to_solr["collection_tesim"]).to eq [subject.id]
      solr_doc = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, work.id).send(:solr_doc)

      expect(subject.members.delete(work)).to eq [work]
      subject.save!
      expect(reloaded_subject.members).to eq []

      solr_doc = ActiveFedora::SolrInstanceLoader.new(ActiveFedora::Base, work.id).send(:solr_doc)
      expect(solr_doc["collection_tesim"]).to be_nil


      work.reload
      expect(work.collections).to eq []
      expect(work.to_solr["collection_tesim"]).to eq []
    end
  end

  it 'has a representative' do
    expect(subject.respond_to?(:representative)).to eq true
  end

  it 'can contain non-collection-member generic files' do
    # GenericFiles that are associated with the Collection,
    # but aren't members, for example, the representative file.
    expect(subject.respond_to?(:generic_files)).to eq true
  end

end
