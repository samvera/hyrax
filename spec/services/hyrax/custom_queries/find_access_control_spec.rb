# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Hyrax::CustomQueries::FindAccessControl do
  let(:query_service) { Hyrax.query_service }
  let(:resource) { double } # TODO: Stubbed waiting for tests
  subject { query_service.custom_queries.find_access_control(for: resource) }

  describe '.find_access_control' do
    # TODO: Need tests for this custom query once inMemory adapter is supported
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
