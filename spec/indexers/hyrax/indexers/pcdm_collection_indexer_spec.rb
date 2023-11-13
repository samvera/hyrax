# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Indexers::PcdmCollectionIndexer do
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_collection, :as_collection_member) }
  let(:indexer_class) { described_class }

  it_behaves_like 'a Collection indexer'
end
