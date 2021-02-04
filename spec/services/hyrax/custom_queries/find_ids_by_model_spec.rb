# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindIdsByModel, valkyrie_adapter: :test_adapter do
  subject(:query_handler) { described_class.new(query_service: Hyrax.query_service) }

  after { Hyrax.persister.wipe! }
  before { Hyrax.persister.wipe! }

  describe '#find_ids_by_model' do
    let(:monographs) { [FactoryBot.valkyrie_create(:monograph), FactoryBot.valkyrie_create(:monograph), FactoryBot.valkyrie_create(:monograph)] }

    before { [FactoryBot.valkyrie_create(:hyrax_work), FactoryBot.valkyrie_create(:hyrax_work)] }

    it 'for a model without resources is empty' do
      expect(query_handler.find_ids_by_model(model: Monograph)).to be_empty
    end

    it 'finds ids matching the model' do
      monographs # create
      expect(query_handler.find_ids_by_model(model: Monograph)).to contain_exactly(*monographs.map(&:id))
    end

    context 'with ids to filter' do
      let(:ids) { ['first_id', 'second_id'] }

      it 'for a model without resources is empty' do
        expect(query_handler.find_ids_by_model(model: Monograph, ids: ids)).to be_empty
      end

      it 'finds ids matching the model' do
        monograph_ids = monographs.map(&:id)
        query_ids = monograph_ids.take(2) + ['fake_id']

        expect(query_handler.find_ids_by_model(model: Monograph, ids: query_ids)).to contain_exactly(*monograph_ids.take(2))
      end
    end
  end
end
