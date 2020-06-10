# frozen_string_literal: true
RSpec.describe SolrHit do
  subject(:solr_hit) { described_class.new "id" => "my:_ID1_" }

  describe "#id" do
    it "extracts the id from the solr hit" do
      expect(solr_hit.id).to eq "my:_ID1_"
    end
  end
end
