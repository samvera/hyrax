# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::ValkyrieCollectionIndexer do
  subject(:indexer) { described_class.new(resource: resource) }
  let(:indexer_class) { described_class }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Collection indexer'
end
