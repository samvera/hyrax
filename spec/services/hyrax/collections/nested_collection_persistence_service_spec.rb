RSpec.describe Hyrax::Collections::NestedCollectionPersistenceService do
  let(:parent) { create(:collection) }
  let(:child) { create(:collection) }

  describe '.persist_nested_collection_for' do
    subject { described_class.persist_nested_collection_for(parent: parent, child: child) }

    it 'creates the relationship between parent and child' do
      subject
      expect(parent.members).to eq([child])
      expect(child.member_of).to eq([parent])
    end
  end
end
