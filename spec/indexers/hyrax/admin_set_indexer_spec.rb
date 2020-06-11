# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetIndexer do
  let(:indexer) { described_class.new(admin_set) }
  let(:admin_set) { build(:complete_admin_set) }
  let(:doc) do
    {
      'generic_type_sim' => ['Admin Set']
    }
  end

  describe "#generate_solr_document" do
    it "has required fields" do
      expect(indexer.generate_solr_document).to match a_hash_including(doc)
    end
  end

  describe 'alternative_title' do
    it 'is stored searchable' do
      expect(indexer.generate_solr_document)
        .to match a_hash_including('alternative_title_tesim' => admin_set.alternative_title)
    end
  end

  describe 'creator' do
    it 'is indexed as a symbol' do
      expect(indexer.generate_solr_document)
        .to match a_hash_including('creator_ssim' => admin_set.creator)
    end
  end

  describe 'description' do
    it 'is stored searchable' do
      expect(indexer.generate_solr_document)
        .to match a_hash_including('description_tesim' => admin_set.description)
    end
  end

  describe 'title' do
    it 'is stored searchable' do
      expect(indexer.generate_solr_document)
        .to match a_hash_including('title_tesim' => admin_set.title)
    end

    it 'is facetable' do
      expect(indexer.generate_solr_document)
        .to match a_hash_including('title_sim' => admin_set.title)
    end
  end
end
