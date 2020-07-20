# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::ValkyrieCollectionIndexer do
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_collection) }
  let(:indexer_class) { described_class }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Collection indexer'
end
