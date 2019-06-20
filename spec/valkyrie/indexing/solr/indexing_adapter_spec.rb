# frozen_string_literal: true
require 'valkyrie/indexing/solr/indexing_adapter'

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapter do
  let(:adapter) { described_class.new(connection: client) }
  let(:client) { Blacklight.default_index.connection }

  describe "#conn" do
    it "returns connection" do
      expect(adapter.conn).to eq client
    end
  end
end
