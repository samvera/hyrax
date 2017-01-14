require 'spec_helper'
describe CurationConcerns::Actors::AddAsMemberOfCollectionsActor do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  let(:collection) { FactoryGirl.create(:collection, user: user, title: ['A good title']) }
  subject do
    CurationConcerns::Actors::ActorStack.new(curation_concern,
                                             user,
                                             [described_class,
                                              CurationConcerns::Actors::GenericWorkActor])
  end
  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
    end

    let(:attributes) do
      { member_of_collection_ids: [collection.id], title: ['test'] }
    end

    it 'does not receive the member_of_collection_ids' do
      expect(root_actor).to receive(:create).with(title: ['test'])
      subject.create(attributes)
    end
  end

  describe 'create' do
    let(:attributes) do
      { member_of_collection_ids: [collection.id], title: ['test'] }
    end

    it 'adds it to the collection' do
      expect(subject.create(attributes)).to be true
      expect(curation_concern.member_of_collections).to eq [collection]
    end

    describe "when work is in user's own collection" do
      it "removes the work from that collection" do
        subject.create(attributes)
        expect(subject.create(member_of_collection_ids: [])).to be true
        expect(curation_concern.member_of_collections).to eq []
      end
    end

    describe "when work is in another user's collection" do
      let(:other_user) { create(:user) }
      let(:collection) { FactoryGirl.create(:collection, user: other_user, title: ['A good title']) }

      it "doesn't remove the work from that collection" do
        subject.create(attributes)
        expect(subject.create(member_of_collection_ids: [])).to be true
        expect(curation_concern.member_of_collections).to eq [collection]
      end
    end
  end
end
