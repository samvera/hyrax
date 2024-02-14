# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ParentCollectionsNavigator, :clean_repo do
  let(:custom_query_service) { Hyrax.custom_queries }

  let!(:collection1) do
    FactoryBot.valkyrie_create(:hyrax_collection, title: ['Parent Collection 1'],
                                                  members: [collection3, work1, work2])
  end
  let!(:collection2) do
    FactoryBot.valkyrie_create(:hyrax_collection, title: ['Parent Collection 1'],
                                                  members: [collection3, work1, work2])
  end
  let(:collection3) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['Child Collection 3']) }
  let(:work1) { FactoryBot.valkyrie_create(:hyrax_work, title: ['Child Work 1']) }
  let(:work2) { FactoryBot.valkyrie_create(:hyrax_work, title: ['Child Work 2']) }

  describe '#find_parent_collections' do
    it 'returns parent collections as Valkyrie resources' do
      parent_collections = custom_query_service.find_parent_collections(resource: collection3)
      expect(parent_collections.map(&:id)).to match_array([collection1.id, collection2.id])
    end
  end

  describe '#find_parent_collection_ids' do
    it 'returns Valkyrie ids for parent collections' do
      parent_collection_ids = custom_query_service.find_parent_collection_ids(resource: work1)
      expect(parent_collection_ids).to match_array([collection1.id, collection2.id])
    end
  end
end
