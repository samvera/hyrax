require 'spec_helper'
describe Hyrax::Actors::AddAsMemberOfCollectionsActor do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  subject do
    Hyrax::Actors::ActorStack.new(curation_concern,
                                  user,
                                  [described_class,
                                   Hyrax::Actors::GenericWorkActor])
  end
  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(Hyrax::Actors::RootActor).to receive(:new).and_return(root_actor)
      allow(Collection).to receive(:find).with('123')
      allow(curation_concern).to receive(:member_of_collections=)
    end

    let(:attributes) do
      { member_of_collection_ids: ['123'], title: ['test'] }
    end

    it 'does not receive the member_of_collection_ids' do
      expect(root_actor).to receive(:create).with(title: ['test'])
      subject.create(attributes)
    end
  end

  describe 'create' do
    let(:collection) { create(:collection) }
    let(:attributes) do
      { member_of_collection_ids: [collection.id], title: ['test'] }
    end

    it 'adds it to the collection' do
      expect(subject.create(attributes)).to be true
      expect(collection.reload.member_objects).to eq [curation_concern]
    end
  end
end
