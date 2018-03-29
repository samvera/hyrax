RSpec.describe PinnedCollection, type: :model do
  describe 'pinning collections' do
    it 'pins collections' do
      pinned = described_class.find_or_initialize_by(collection: 123, user_id: 1, pinned: 1)
      expect(pinned.collection).to eq '123'
      expect(pinned.user_id).to eq 1
      expect(pinned.pinned).to eq 1
    end
  end

  describe 'returning pinned collections' do
    before do
      described_class.create!(collection: 123, user_id: 1, pinned: 1)
      described_class.create!(collection: 321, user_id: 1, pinned: 0)
    end

    it 'returns users pinned collections' do
      record = []
      records = described_class.where(user_id: 1, pinned: 1).to_a

      # Remove timestamps
      records.each do |r|
        record << { user_id: r[:user_id], pinned: r[:pinned], collection: r[:collection] }
      end

      expect(record).to match_array([{ collection: '123', user_id: 1, pinned: 1 }])
    end
  end
end
