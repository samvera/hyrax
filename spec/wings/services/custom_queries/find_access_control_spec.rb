# frozen_string_literal: true
require 'wings_helper'
require 'wings/services/custom_queries/find_access_control'

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Wings::CustomQueries::FindAccessControl do
  let(:query_service) { Hyrax.query_service }
  let(:resource) { double } # TODO: Stubbed waiting for tests
  let(:subject) { query_service.custom_queries.find_access_control(for: resource) }

  describe '.find_access_control' do
    # TODO: Need tests for this custom query
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
