require 'spec_helper'
require 'rspec/active_model/mocks'

describe CurationConcerns::CollectionBehavior do
  # All behavior for Collection are defined in CC::CollectionBehavior, so we use
  # a Collection instance to test.
  let(:collection) { FactoryGirl.build(:collection) }
  subject { collection }

  it 'does not allow a collection to be saved without a title' do
    subject.title = nil
    expect { subject.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end

  describe "indexer" do
    subject { Collection.indexer }
    it { is_expected.to eq CurationConcerns::CollectionIndexer }
  end

  describe '::bytes' do
    subject { collection.bytes }

    context 'with no items' do
      before { collection.save }
      it { is_expected.to eq 0 }
    end

    context 'with two 50 byte files' do
      let(:bitstream) { double('content', size: '50') }
      let(:file) { mock_model ::FileSet, content: bitstream }
      before { allow(collection).to receive(:members).and_return([file, file]) }
      it { is_expected.to eq 100 }
    end
  end

  context '.add_member' do
    let(:collectible?) { nil }
    let(:proposed_collectible) { double(collections: []) }
    before(:each) do
      allow(proposed_collectible).to receive(:can_be_member_of_collection?).with(subject).and_return(collectible?)
      # Added for solrizing interface.
      allow(proposed_collectible).to receive(:pcdm_object?).and_return(true)
      allow(proposed_collectible).to receive(:collection?).and_return(false)
      allow(proposed_collectible).to receive(:id).and_return("1")
      allow(proposed_collectible).to receive(:save).and_return(true)
    end

    context 'with itself' do
      it 'does not add it to the collection\'s members' do
        expect do
          subject.add_member(subject)
        end.to_not change { subject.members.size }
      end
    end

    context 'with a non-collectible object' do
      let(:collectible?) { false }
      it 'does not add it to the collection\'s members' do
        expect do
          subject.add_member(proposed_collectible)
        end.to_not change { subject.members.size }
      end
    end

    context 'with a collectible object' do
      let(:collectible?) { true }
      before do
        allow(collection).to receive(:members).and_return([])
      end
      it 'adds it to the collection\'s members' do
        expect do
          subject.add_member(proposed_collectible)
        end.to change { subject.members.size }.by(1)
      end
    end
  end

  context 'is a pcdm:Collection instance' do
    let(:collection1) { FactoryGirl.build(:collection) }
    let(:work1) { FactoryGirl.build(:work) }

    it 'is a pcdm:Collection' do
      expect(subject.pcdm_collection?).to be true
      expect(subject.type).to include Hydra::PCDM::Vocab::PCDMTerms.Collection
    end
    it 'does not be a pcdm:Object' do
      expect(subject.pcdm_object?).to be false
      expect(subject.type).to_not include Hydra::PCDM::Vocab::PCDMTerms.Object
    end

    it 'contains objects' do
      expect(subject.works).to eq []
      expect(subject.work_ids).to eq []
      expect(subject.members << work1).to eq [work1]
      expect(subject.works).to eq [work1]
      expect(subject.work_ids).to eq [work1.id]
    end

    it 'contains collections' do
      expect(subject.collections).to eq []
      expect(subject.collection_ids).to eq []
      expect(subject.members << collection1).to eq [collection1]
      expect(subject.collections).to eq [collection1]
      expect(subject.collection_ids).to eq [collection1.id]
    end
    it 'has related objects' do
      expect(subject.related_objects).to eq []
      expect(subject.related_objects << work1).to eq [work1]
      expect(subject.related_objects).to eq [work1]
    end
    it 'has parent collections' do
      expect(subject.in_collections).to eq []
      expect(collection1.members << subject).to eq [subject]
      # Function of auto-save/indexing issues.
      subject.save
      collection1.save
      expect(subject.in_collections).to eq [collection1]
    end
  end
end
