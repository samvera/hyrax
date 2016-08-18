require 'spec_helper'

RSpec.describe Sufia::WorkIndexer do
  let(:indexer) { described_class.new(work) }
  describe "#generate_solr_document" do
    let(:work) { create(:generic_work, admin_set: create(:admin_set)) }
    subject(:document) { indexer.generate_solr_document }

    it "indexes the correct fields" do
      expect(document.fetch('admin_set_sim')).to eq ["Title 1"]
      expect(document.fetch('admin_set_tesim')).to eq ["Title 1"]
    end
  end
end
