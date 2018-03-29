RSpec.describe Hyrax::Admin::PinCollectionPresenter do
  let(:instance) { described_class.new(collection: 123, user_id: 2, pinned: 1) }
  let(:instance2) { described_class.new(user_id: 2) }
  let(:results) { true }
  let(:all_results) { [{ collection: 123, user_id: 2, pinned: 1 }] }

  describe '#pin_collection' do
    before do
      allow(::PinnedCollection).to receive(:pin_collection).and_return(results)
    end

    subject { instance.pin_collection }

    it 'pins collection and returns result' do
      expect(subject).to eq true
    end
  end

  describe '#all_pinned_collections' do
    before do
      allow(instance2).to receive(:all_pinned_collections).and_return(all_results)
    end

    subject { instance2.all_pinned_collections }

    it 'returns pinned collections' do
      expect(subject).to match_array(all_results)
    end
  end
end
