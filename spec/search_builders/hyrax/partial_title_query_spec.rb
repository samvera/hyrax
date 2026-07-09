# frozen_string_literal: true

RSpec.describe Hyrax::PartialTitleQuery do
  let(:includer) do
    Class.new do
      include Hyrax::PartialTitleQuery
      public :partial_title_query # expose the protected helper for testing
    end.new
  end

  describe '#partial_title_query' do
    it 'searches the term across title, description, creator, and keyword' do
      query = includer.partial_title_query('repel')
      expect(query).to include('title_tesim:(repel)')
        .and include('description_tesim:(repel)')
        .and include('creator_tesim:(repel)')
        .and include('keyword_tesim:(repel)')
    end

    it 'also matches a title that starts with the term (partial typing)' do
      query = includer.partial_title_query('repel')
      expect(query).to include('title_tesim:(repel*)')
    end

    it 'matches a title beginning with every typed word' do
      query = includer.partial_title_query('repel ani')
      expect(query).to include('title_tesim:(repel* AND ani*)')
    end

    it 'treats Solr special characters as literal text, not query syntax' do
      query = includer.partial_title_query('a:b*')
      expect(query).to include('title_tesim:(a\\:b\\*)')
    end

    it 'escapes special characters in a word while still matching it as a prefix' do
      query = includer.partial_title_query('a:b')
      expect(query).to include('title_tesim:(a\\:b*)')
    end
  end
end
