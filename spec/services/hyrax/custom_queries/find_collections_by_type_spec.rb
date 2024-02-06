# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindCollectionsByType, valkyrie_adapter: :test_adapter, skip: !Hyrax.config.use_valkyrie? || !Hyrax.config.disable_wings do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:adapter)           { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:collection_type)   { FactoryBot.create(:collection_type) }
  let(:persister)         { adapter.persister }
  let(:type_gid)          { collection_type.to_global_id }
  let(:query_service)     { adapter.query_service }

  describe '#find_collections_by_type' do
    before { persister.wipe! }

    context 'when there are no collections' do
      it 'is empty' do
        expect(query_handler.find_collections_by_type(global_id: type_gid))
          .to be_empty
      end
    end

    describe 'when there are collections with the type' do
      let(:collection_with_default_type) { FactoryBot.valkyrie_create(:hyrax_collection) }
      let(:non_collection_model)         { FactoryBot.valkyrie_create(:hyrax_work) }

      let(:collections_with_target_type) do
        [FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: type_gid),
         FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: type_gid)]
      end

      before do # force create all the models
        non_collection_model
        collection_with_default_type
        collections_with_target_type
      end

      it 'returns exactly the collections of the type' do
        expect(query_handler.find_collections_by_type(global_id: type_gid))
          .to contain_exactly(*collections_with_target_type)
      end
    end
  end
end
