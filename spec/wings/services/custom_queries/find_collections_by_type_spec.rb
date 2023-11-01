# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/services/custom_queries/find_collections_by_type'

RSpec.describe Wings::CustomQueries::FindCollectionsByType, :active_fedora, :clean_repo do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:collection_type)   { FactoryBot.create(:collection_type) }
  let(:type_gid)          { collection_type.to_global_id }
  let(:query_service)     { Hyrax.query_service }

  describe '#find_collections_by_type' do
    context 'when there are no collections' do
      it 'is empty' do
        expect(query_handler.find_collections_by_type(global_id: type_gid))
          .to be_empty
      end
    end

    context 'when collections exist' do
      let(:collection_with_default_type) { FactoryBot.create(:collection) }
      let(:non_collection_model)         { FactoryBot.create(:work) }

      let(:collections_with_target_type) do
        FactoryBot.create_list(:collection_lw, 3, collection_type_gid: type_gid)
      end

      before do # force create all the models
        non_collection_model
        collection_with_default_type
        collections_with_target_type
      end

      it 'returns only the collections of requested type' do
        expect(query_handler.find_collections_by_type(global_id: type_gid).map(&:id))
          .to contain_exactly(*collections_with_target_type.map(&:id))
      end

      it 'returns Hyrax::PcdmCollection instances' do
        expect(query_handler.find_collections_by_type(global_id: type_gid))
          .to contain_exactly be_a(Hyrax::PcdmCollection),
                              be_a(Hyrax::PcdmCollection),
                              be_a(Hyrax::PcdmCollection)
      end
    end
  end
end
