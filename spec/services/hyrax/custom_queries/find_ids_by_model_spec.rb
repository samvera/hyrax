# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindIdsByModel, :clean_repo do
  subject(:query_handler) { described_class.new(query_service: Hyrax.query_service) }

  shared_examples 'find_ids_by_model' do |use_solr|
    it 'finds ids matching the model' do
      expect(query_handler.find_ids_by_model(model: Monograph, use_solr: use_solr).count).to be_zero
      monographs # create
      expect(query_handler.find_ids_by_model(model: Monograph, use_solr: use_solr)).to contain_exactly(*monographs.map(&:id))
    end

    context 'with ids to filter' do
      let(:ids) { ['first_id', 'second_id'] }

      it 'finds ids matching the model' do
        expect(query_handler.find_ids_by_model(model: Monograph, ids: ids, use_solr: use_solr).count).to be_zero
        monograph_ids = monographs.map(&:id) # create
        query_ids = monograph_ids.take(2) + ['fake_id']

        expect(query_handler.find_ids_by_model(model: Monograph, ids: query_ids, use_solr: use_solr)).to contain_exactly(*monograph_ids.take(2))
      end
    end
  end

  describe '#find_ids_by_model' do
    let(:monographs) { [FactoryBot.valkyrie_create(:monograph), FactoryBot.valkyrie_create(:monograph), FactoryBot.valkyrie_create(:monograph)] }

    before { [FactoryBot.valkyrie_create(:hyrax_work), FactoryBot.valkyrie_create(:hyrax_work)] }

    context 'using solr' do
      it_should_behave_like('find_ids_by_model', true)
    end

    context 'not using solr' do
      it_should_behave_like('find_ids_by_model', false)
    end
  end
end
