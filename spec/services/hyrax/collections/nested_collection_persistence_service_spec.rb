# frozen_string_literal: true
RSpec.describe Hyrax::Collections::NestedCollectionPersistenceService do
  let(:parent) { FactoryBot.valkyrie_create(:hyrax_collection) }
  let(:child) { FactoryBot.valkyrie_create(:hyrax_collection) }

  describe '.persist_nested_collection_for' do
    subject { described_class.persist_nested_collection_for(parent: parent, child: child) }

    it 'creates the relationship between parent and child' do
      subject
      expect(Hyrax.custom_queries.find_parent_collection_ids(resource: child)).to contain_exactly(parent.id)
      expect(Hyrax.custom_queries.find_child_collection_ids(resource: parent).to_a).to eq [child.id]
    end
  end

  describe '.remove_nested_relationship_for', :clean_repo do
    subject { described_class.remove_nested_relationship_for(parent: parent, child: child) }

    before do
      described_class.persist_nested_collection_for(parent: parent, child: child)
    end

    it 'removes the relationship between parent and child' do
      subject
      expect(Hyrax.custom_queries.find_parent_collection_ids(resource: child)).to be_empty
      expect(Hyrax.custom_queries.find_child_collection_ids(resource: parent).to_a).to be_empty
    end
  end
end
