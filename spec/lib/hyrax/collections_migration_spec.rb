require 'hyrax/collections_migration'

RSpec.describe Hyrax::CollectionsMigration do
  let(:collection1) { create(:collection, id: 'alien', title: ['alien movies']) }
  let(:collection2) { create(:collection, id: 'predator', title: ['predator movies']) }
  let(:work1) { create(:work, title: ['alien resurrection']) }
  let(:work2) { create(:work, title: ['the predator']) }
  let(:work3) { create(:work, title: ['alien vs. predator']) }

  before do
    collection1.members = [work1, work3]
    collection2.members = [work2, work3]
  end

  describe '.run' do
    it 'moves relationship from collection#members to curation_concern#member_of_collections' do
      expect(collection1.members.to_a.size).to eq 2
      expect(collection2.members.to_a.size).to eq 2
      expect(work1.member_of_collections.to_a.size).to eq 0
      expect(work2.member_of_collections.to_a.size).to eq 0
      expect(work3.member_of_collections.to_a.size).to eq 0
      described_class.run
      expect(collection1.reload.members.to_a.size).to eq 0
      expect(collection2.reload.members.to_a.size).to eq 0
      expect(work1.reload.member_of_collections.to_a.size).to eq 1
      expect(work1.member_of_collection_ids.first).to eq 'alien'
      expect(work2.reload.member_of_collections.to_a.size).to eq 1
      expect(work2.member_of_collection_ids.first).to eq 'predator'
      expect(work3.reload.member_of_collections.to_a.size).to eq 2
      expect(work3.member_of_collection_ids).to include 'predator'
      expect(work3.member_of_collection_ids).to include 'alien'
    end
  end
end
