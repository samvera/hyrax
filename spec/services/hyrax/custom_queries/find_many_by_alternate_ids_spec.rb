# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Wings::CustomQueries::FindManyByAlternateIds do
  let(:query_service) { Hyrax.query_service }
  let(:id_list) { double } # TODO: Stubbed waiting for tests
  subject { query_service.custom_queries.find_many_by_alternate_ids(alternate_ids: id_list) }

  describe '.find_many_by_alternate_ids' do
    context 'with Valkyrie::ID input' do
      # TODO: Need tests for this custom query once inMemory adapter is supported
    end

    context 'when list includes an invalid id' do
      # TODO: Need tests for this custom query once inMemory adapter is supported
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
