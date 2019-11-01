# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::ValkyrieWorkIndexer do
  let(:indexer) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }
  let(:indexer_class) { described_class }

  it_behaves_like 'a Hyrax::Resource indexer'
  it_behaves_like 'a Core metadata indexer'
end
