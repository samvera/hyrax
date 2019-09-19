# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Hyrax::CustomQueries::FindFileMetadata do
  let(:query_service) { Hyrax.query_service }
  let(:valk_id) { double } # TODO: Stubbed waiting for tests
  subject { query_service.custom_queries.find_file_metadata_by(id: valk_id) }

  describe '.find_file_metadata_by' do
    # TODO: Need tests for this custom query once inMemory adapter is supported
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
