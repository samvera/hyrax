# frozen_string_literal: true

RSpec.describe Hyrax::CompoundWorkResolver do
  describe '.url?' do
    it 'is true for http(s) URLs' do
      expect(described_class.url?('https://example.org/x')).to be true
      expect(described_class.url?('http://example.org')).to be true
    end

    it 'is false for a work id (UUID/noid)' do
      expect(described_class.url?('691b0622-3f77-48ad-a00f-00c254b83165')).to be false
      expect(described_class.url?('abc123')).to be false
    end

    it 'is false for blank' do
      expect(described_class.url?('')).to be false
      expect(described_class.url?(nil)).to be false
    end
  end

  describe '.title_and_path' do
    let(:id) { 'work-123' }

    it 'resolves the title from Solr and the model-agnostic show path' do
      allow(Hyrax::SolrService).to receive(:query)
        .and_return([{ 'title_tesim' => ['Resolved Title'] }])

      title, path = described_class.title_and_path(id)
      expect(title).to eq('Resolved Title')
      expect(path).to eq('/catalog/work-123')
    end

    it 'falls back to the id when no title is indexed' do
      allow(Hyrax::SolrService).to receive(:query).and_return([])
      title, = described_class.title_and_path(id)
      expect(title).to eq('work-123')
    end

    it 'falls back to the id when the Solr lookup raises' do
      allow(Hyrax::SolrService).to receive(:query).and_raise(StandardError)
      title, = described_class.title_and_path(id)
      expect(title).to eq('work-123')
    end
  end

  describe '.resolve' do
    let(:id) { 'work-123' }

    it 'returns [title, path] when a matching work is indexed' do
      allow(Hyrax::SolrService).to receive(:query)
        .and_return([{ 'title_tesim' => ['Resolved Title'] }])
      expect(described_class.resolve(id)).to eq(['Resolved Title', '/catalog/work-123'])
    end

    it 'returns nil when no work matches (so the caller renders plain text)' do
      allow(Hyrax::SolrService).to receive(:query).and_return([])
      expect(described_class.resolve(id)).to be_nil
    end

    it 'returns nil when the Solr lookup raises' do
      allow(Hyrax::SolrService).to receive(:query).and_raise(StandardError)
      expect(described_class.resolve(id)).to be_nil
    end
  end
end
