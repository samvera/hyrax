# frozen_string_literal: true

RSpec.describe Hyrax::CompoundWorkResolver do
  # Stub a Solr hit for `id` with the given fields (e.g. has_model_ssim/title).
  def stub_solr(fields)
    allow(Hyrax::SolrService).to receive(:query).and_return([fields].compact)
  end

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

  describe '.resolve' do
    let(:id) { 'rec-123' }

    it 'links a work to its work show page' do
      stub_solr('id' => id, 'title_tesim' => ['A Work'], 'has_model_ssim' => ['GenericWork'])
      title, path = described_class.resolve(id)
      expect(title).to eq('A Work')
      expect(path).to eq("/concern/generic_works/#{id}")
    end

    it 'links a collection to its collection show page' do
      stub_solr('id' => id, 'title_tesim' => ['A Collection'], 'has_model_ssim' => [Hyrax.config.collection_model])
      title, path = described_class.resolve(id)
      expect(title).to eq('A Collection')
      expect(path).to eq("/collections/#{id}")
    end

    it 'falls back to the catalog route when the model is not a routable work/collection' do
      stub_solr('id' => id, 'title_tesim' => ['Mystery'])
      _title, path = described_class.resolve(id)
      expect(path).to eq("/catalog/#{id}")
    end

    it 'returns nil when nothing matches (so the caller renders plain text)' do
      stub_solr(nil)
      expect(described_class.resolve(id)).to be_nil
    end

    it 'returns nil when the Solr lookup raises' do
      allow(Hyrax::SolrService).to receive(:query).and_raise(StandardError)
      expect(described_class.resolve(id)).to be_nil
    end
  end

  describe '.title_and_path' do
    let(:id) { 'rec-123' }

    it 'resolves the title and the work show path' do
      stub_solr('id' => id, 'title_tesim' => ['Resolved Title'], 'has_model_ssim' => ['GenericWork'])
      title, path = described_class.title_and_path(id)
      expect(title).to eq('Resolved Title')
      expect(path).to eq("/concern/generic_works/#{id}")
    end

    it 'falls back to the id when no record is indexed' do
      stub_solr(nil)
      title, = described_class.title_and_path(id)
      expect(title).to eq(id)
    end

    it 'falls back to the id when the Solr lookup raises' do
      allow(Hyrax::SolrService).to receive(:query).and_raise(StandardError)
      title, = described_class.title_and_path(id)
      expect(title).to eq(id)
    end
  end
end
