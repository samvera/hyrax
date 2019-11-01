# frozen_string_literal: true

RSpec.shared_examples 'a Hyrax::Resource indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:ids)         { ['id1', 'id2'] }
  let(:resource)    { Hyrax::Resource.new(alternate_ids: ids) }

  describe '#to_solr' do
    it 'indexes alternate_ids' do
      expect(indexer.to_solr)
        .to include(alternate_ids_sm: a_collection_containing_exactly(*ids))
    end
  end
end

RSpec.shared_examples 'a Core metadata indexer' do
  subject(:indexer) { indexer_class.new(resource: resource) }
  let(:titles)      { ['Comet in Moominland', 'Finn Family Moomintroll'] }
  let(:resource)    { Hyrax::Work.new(title: titles) }

  describe '#to_solr' do
    it 'indexes title as text' do
      expect(indexer.to_solr)
        .to include(title_tesim: a_collection_containing_exactly(*titles))
    end

    it 'indexes title as string' do
      expect(indexer.to_solr)
        .to include(title_sim: a_collection_containing_exactly(*titles))
    end
  end
end
