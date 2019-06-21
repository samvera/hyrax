# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/indexing/solr/indexing_adapter'

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapter do
  subject(:adapter) { described_class.new }

  describe "#connection" do
    it "returns connection" do
      expect(adapter.connection.uri.to_s).to include 'valkyrie-test'
    end
  end
end
