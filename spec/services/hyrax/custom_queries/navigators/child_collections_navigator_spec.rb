# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator, :clean_repo do
  let(:custom_query_service) { Hyrax.custom_queries }

  let(:collection1)    { valkyrie_create(:hyrax_collection, title: ['Collection 1']) }
  let(:collection2)    { valkyrie_create(:hyrax_collection, title: ['Child Collection 1']) }
  let(:collection3)    { valkyrie_create(:hyrax_collection, title: ['Child Collection 2']) }

  before do
    resources = [collection2, collection3]
    resources.each { |res| res.member_of_collection_ids += [collection1.id] }
    resources.each { |res| Hyrax.persister.save(resource: res) }
  end

  describe '#find_child_collections' do
    it 'returns only child collections as Valkyrie resources' do
      child_collections = custom_query_service.find_child_collections(resource: collection1)
      expect(child_collections.map(&:id)).to match_array([collection2.id, collection3.id])
    end
  end

  describe '#find_child_collection_ids' do
    it 'returns Valkyrie ids for child collections only' do
      child_collection_ids = custom_query_service.find_child_collection_ids(resource: collection1)
      expect(child_collection_ids).to match_array([collection2.id, collection3.id])
    end
  end
end
