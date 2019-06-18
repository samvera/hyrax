require 'spec_helper'

RSpec.describe Hyrax::SolrQueryBuilderService do
  describe '#construct_query_for_ids' do
    it "generates a useable solr query from an array of Fedora ids" do
      expect(described_class.construct_query_for_ids(["my:_ID1_", "my:_ID2_", "my:_ID3_"])).to eq '{!terms f=id}my:_ID1_,my:_ID2_,my:_ID3_'
    end
    it "returns a valid solr query even if given an empty array as input" do
      expect(described_class.construct_query_for_ids([""])).to eq "id:NEVER_USE_THIS_ID"
    end
  end
end

