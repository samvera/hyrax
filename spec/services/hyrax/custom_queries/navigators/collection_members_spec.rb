# frozen_string_literal: true

RSpec.describe Hyrax::CustomQueries::Navigators::CollectionMembers, valkyrie_adapter: :test_adapter do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:adapter)           { Hyrax.metadata_adapter }
  let(:persister)         { adapter.persister }
  let(:query_service)     { adapter.query_service }

  describe '#find_collections_for' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

    it 'is empty with no collections' do
      expect(query_handler.find_collections_for(resource: work))
        .to be_empty
    end

    context 'when it is a member of collections' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :as_member_of_multiple_collections) }

      it 'finds collections' do
        expect(query_handler.find_collections_for(resource: work).map(&:id))
          .to contain_exactly(*work.member_of_collection_ids)
      end
    end
  end

  describe '#find_members_of' do
    let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

    it 'is empty with no member' do
      expect(query_handler.find_members_of(collection: collection))
        .to be_empty
    end

    context 'when collections has inverse work members' do
      let(:work) do
        FactoryBot.valkyrie_create(:hyrax_work, member_of_collection_ids: collection.id)
      end

      before { work } # save work with collection membership

      it 'finds collections' do
        expect(query_handler.find_members_of(collection: collection))
          .to contain_exactly(work)
      end
    end
  end
end
