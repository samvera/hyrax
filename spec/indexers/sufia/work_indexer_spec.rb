require 'spec_helper'

RSpec.describe Sufia::WorkIndexer do
  let(:indexer) { described_class.new(work) }

  describe "#generate_solr_document" do
    let(:work) { create(:generic_work, admin_set: admin_set) }
    let(:admin_set) { create(:admin_set, title: ['Title One']) }
    subject(:document) { indexer.generate_solr_document }

    it "indexes the correct fields" do
      expect(document.fetch('admin_set_sim')).to eq ["Title One"]
      expect(document.fetch('admin_set_tesim')).to eq ["Title One"]
    end
  end
end
