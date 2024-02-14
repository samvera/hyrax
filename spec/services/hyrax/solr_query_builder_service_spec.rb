# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::SolrQueryBuilderService do
  describe '.construct_query_for_ids' do
    it "generates a useable solr query from an array of Fedora ids" do
      expect(described_class.construct_query_for_ids(["my:_ID1_", "my:_ID2_", "my:_ID3_"])).to eq '{!terms f=id}my:_ID1_,my:_ID2_,my:_ID3_'
    end
    it "returns a valid solr query even if given an empty array as input" do
      expect(described_class.construct_query_for_ids([""])).to eq "id:NEVER_USE_THIS_ID"
    end
  end

  describe ".construct_query" do
    it "generates a query clause" do
      expect(described_class.construct_query('id' => "my:_ID1_")).to eq '_query_:"{!field f=id}my:_ID1_"'
    end
  end

  describe ".construct_query_for_model" do
    it "generates a query clause" do
      expect(described_class.construct_query_for_model(::Collection, 'id' => "my:_ID1_")).to eq "(_query_:\"{!field f=id}my:_ID1_\" AND _query_:\"{!field f=has_model_ssim}#{::Collection}\")"
    end
  end
end
