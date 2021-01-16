# frozen_string_literal: true

RSpec.describe Hyrax::SingleCollectionSearchBuilder do
  subject(:builder) { described_class.new(scope) }
  let(:scope) { FakeSearchBuilderScope.new }

  shared_context 'with search params' do
    let(:params) { { id: 'a_collection_id' } }

    before { builder.with(params) }
  end

  describe 'Hyrax::SearchService collaboration' do
    let(:search_service) do
      Hyrax::SearchService.new(config: scope.blacklight_config,
                               user_params: params,
                               scope: scope,
                               search_builder_class: described_class)
    end

    include_context 'with search params'

    it 'finds none' do
      expect(search_service.search_results[0].documents).to be_empty
    end

    context 'with an indexed public collection' do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, :public) }
      let(:params) { { id: collection.id } }

      before { collection } # index it

      it 'finds one' do
        expect(search_service.search_results[0].documents)
          .to contain_exactly(have_attributes(id: collection.id))
      end
    end
  end

  describe "#to_hash" do
    it 'with no parameters raises an error eagerly' do
      expect { builder.to_hash }.to raise_error KeyError
    end

    context 'with parameters' do
      include_context 'with search params'

      it 'includes collection in type filter' do
        expect(builder.to_hash['fq']).to include(/f\=has_model_ssim\}.*Collection/)
      end

      it 'searches for the provided id' do
        expect(builder.to_hash['fq']).to include '{!raw f=id}a_collection_id'
      end

      it 'filters suppressed' do
        expect(builder.to_hash['fq']).to include '-suppressed_bsi:true'
      end
    end
  end
end
