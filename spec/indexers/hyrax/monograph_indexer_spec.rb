# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe MonographIndexer do
  let(:indexer) { described_class.new(resource: resource) }
  let(:resource) { build(:monograph) }
  let(:indexer_class) { described_class }

  it 'has resource' do
    expect(indexer.resource).to eq resource
  end
end
