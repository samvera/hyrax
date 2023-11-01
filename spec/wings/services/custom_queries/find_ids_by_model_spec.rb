# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/services/custom_queries/find_ids_by_model'

RSpec.describe Wings::CustomQueries::FindIdsByModel, :clean_repo, valkyrie_adapter: :wings_adapter do
  subject(:query_handler) { described_class.new(query_service: Hyrax.query_service) }

  describe '#find_ids_by_model' do
    let(:monographs) { [FactoryBot.valkyrie_create(:monograph), FactoryBot.valkyrie_create(:monograph), FactoryBot.valkyrie_create(:monograph)] }

    before { [FactoryBot.valkyrie_create(:hyrax_work), FactoryBot.valkyrie_create(:hyrax_work)] }

    it 'for a model without resources is empty' do
      expect(query_handler.find_ids_by_model(model: Monograph).to_a).to be_empty
    end

    it 'finds ids matching the model' do
      expect(query_handler.find_ids_by_model(model: Monograph)).to contain_exactly(*monographs.map(&:id))
    end

    context 'with ids to filter' do
      let(:ids) { ['first_id', 'second_id'] }

      it 'for a model without resources is empty' do
        expect(query_handler.find_ids_by_model(model: Monograph, ids: ids).to_a).to be_empty
      end

      it 'finds ids matching the model' do
        monograph_ids = monographs.map(&:id)
        query_ids = monograph_ids.take(2) + ['fake_id']

        expect(query_handler.find_ids_by_model(model: Monograph, ids: query_ids)).to contain_exactly(*monograph_ids.take(2))
      end
    end

    context 'for admin sets' do
      let(:admin_sets) { [FactoryBot.valkyrie_create(:hyrax_admin_set), FactoryBot.create(:admin_set)] }

      it 'finds them all as Hyrax::AdministrativeSet' do
        expect(query_handler.find_ids_by_model(model: Hyrax::AdministrativeSet)).to contain_exactly(*admin_sets.map(&:id))
      end
    end

    context 'for collections' do
      let(:collections) { [FactoryBot.valkyrie_create(:hyrax_collection), FactoryBot.create(:collection)] }

      it 'finds them all as Hyrax::PcdmCollection' do
        expect(query_handler.find_ids_by_model(model: Hyrax::PcdmCollection)).to contain_exactly(*collections.map(&:id))
      end
    end

    context 'when paging is needed' do
      subject(:query_handler) { described_class.new(query_service: Hyrax.query_service, query_rows: 2) }

      it 'includes all the results' do
        expect(query_handler.find_ids_by_model(model: Monograph)).to contain_exactly(*monographs.map(&:id))
      end

      it 'finds ids matching the query' do
        monograph_ids = monographs.map(&:id)
        query_ids = monograph_ids.take(2) + ['fake_id']

        expect(query_handler.find_ids_by_model(model: Monograph, ids: query_ids)).to contain_exactly(*monograph_ids.take(2))
      end
    end
  end
end
