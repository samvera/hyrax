require 'spec_helper'

RSpec.describe Hyrax::Base do
  describe '#search_by_id' do
    context 'with a document in solr' do
      let(:doc) { instance_double(Hash) }

      before do
        expect(Hyrax::SolrService).to receive(:query).with('id:a_fade_id', hash_including(rows: 1)).and_return([doc])
      end

      it "returns the document" do
        expect(described_class.search_by_id('a_fade_id')).to eq doc
      end
    end

    context 'without a document in solr' do
      before do
        expect(Hyrax::SolrService).to receive(:query).with('id:a_fade_id', hash_including(rows: 1)).and_return([])
      end

      it "returns the document" do
        expect { described_class.search_by_id('a_fade_id') }.to raise_error ActiveFedora::ObjectNotFoundError, "Object 'a_fade_id' not found in solr"
      end
    end
  end
end
