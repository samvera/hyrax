# frozen_string_literal: true

RSpec.describe Hyrax::SingleCollectionSearchBuilder do
  subject(:builder) { described_class.new(scope) }
  let(:scope) { FakeSearchBuilderScope.new }

  shared_context 'with search params' do
    let(:params) { { id: 'a_collection_id' } }

    before { builder.with(params) }
  end

  describe "#to_hash" do
    it 'with no parameters raises an error eagerly' do
      expect { builder.to_hash }.to raise_error KeyError
    end

    context 'with parameters' do
      include_context 'with search params'

      it 'includes collection and pcdmcollection in type filter' do
        expect(builder.to_hash['fq']).to include(/f\=has_model_ssim\}.*Collection,Hyrax::PcdmCollection/)
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
