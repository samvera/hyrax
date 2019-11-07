# frozen_string_literal: true

RSpec.describe Hyrax::CustomQueries::FindManyByAlternateIds do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:adapter)           { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)         { adapter.persister }
  let(:query_service)     { adapter.query_service }

  let(:ids) { resources.map { |r| r.alternate_ids.first } }

  let(:resources) do
    [persister.save(resource: Hyrax::Resource.new(alternate_ids: ['1'])),
     persister.save(resource: Hyrax::Resource.new(alternate_ids: ['2'])),
     persister.save(resource: Hyrax::Resource.new(alternate_ids: ['3']))]
  end

  before { persister.wipe! }

  describe '#find_many_by_alternate_ids' do
    it 'returns empty with no ids' do
      expect(query_handler.find_many_by_alternate_ids(alternate_ids: []).count)
        .to eq 0
    end

    context 'with Valkyrie::ID input' do
      it 'returns matching resources' do
        expect(query_handler.find_many_by_alternate_ids(alternate_ids: ids))
          .to contain_exactly(*resources)
      end
    end

    context 'when list includes an invalid id' do
      let(:ids) { resources.map { |r| r.alternate_ids.first } + ['fake_id'] }

      it 'raises ObjectNotFoundError' do
        expect { query_handler.find_many_by_alternate_ids(alternate_ids: ids).to_a }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
