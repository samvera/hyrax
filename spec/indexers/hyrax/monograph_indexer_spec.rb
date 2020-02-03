# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe MonographIndexer do
  let(:indexer) { described_class.new(resource: resource) }
  let(:resource) { build(:monograph) }
  let(:indexer_class) { described_class }
  let(:solr_document) { {} } # for now
  let(:change_set) { Hyrax::ChangeSet.for(resource) }

  it 'has resource' do
    expect(indexer.resource).to eq resource
  end

  context '#to_solr' do
    before do
      change_set.title = 'comet in moominland'
      change_set.creator = 'Tove Jansson'
      change_set.sync
    end

    it 'Indexes core_metadata' do
      expect(indexer.to_solr[:title_sim]).to eq resource.title
      expect(indexer.to_solr[:title_tesim]).to eq resource.title
    end

    it 'Indexes basic_metadata' do
      expect(indexer.to_solr[:creator_sim]).to eq resource.creator
      expect(indexer.to_solr[:creator_tesim]).to eq resource.creator
    end
  end
end