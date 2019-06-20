# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/indexing/solr/indexing_adapter'

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapter do
  let(:adapter) { described_class.new(connection: client) }
  let(:client) { RSolr.connect(VALKYRIE_SOLR_TEST_URL) }

  describe "#connection" do
    it "returns connection" do
      expect(adapter.connection).to eq client
    end
  end
end
