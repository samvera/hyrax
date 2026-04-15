# frozen_string_literal: true

RSpec.describe Hyrax::UncappedSolrQuery do
  describe '.call' do
    let(:documents) { [double("doc1"), double("doc2"), double("doc3")] }

    def mock_response(num_found:, docs: [])
      double("Blacklight::Solr::Response",
             response: { 'numFound' => num_found },
             documents: docs)
    end

    context 'when there are no results' do
      let(:count_response) { mock_response(num_found: 0) }

      it 'returns the count response without a second query' do
        call_count = 0
        result = described_class.call do |rows|
          call_count += 1
          expect(rows).to eq 0
          count_response
        end

        expect(result).to eq count_response
        expect(call_count).to eq 1
      end
    end

    context 'when there are results' do
      let(:count_response) { mock_response(num_found: 3) }
      let(:full_response) { mock_response(num_found: 3, docs: documents) }

      it 'makes two queries: first with rows=0, then with rows=numFound' do
        rows_requested = []
        result = described_class.call do |rows|
          rows_requested << rows
          rows.zero? ? count_response : full_response
        end

        expect(rows_requested).to eq [0, 3]
        expect(result).to eq full_response
      end
    end
  end
end
