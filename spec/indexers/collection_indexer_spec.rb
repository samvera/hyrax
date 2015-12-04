require 'spec_helper'

describe CurationConcerns::CollectionIndexer do
  let(:indexer) { described_class.new(collection) }
  let(:collection) { build(:collection) }

  before { allow(collection).to receive(:bytes).and_return(1000) }
  describe "#generate_solr_document" do
    subject { indexer.generate_solr_document }

    it "has generic type" do
      expect(subject.fetch('generic_type_sim')).to eq ["Collection"]
    end

    it "has bytes" do
      expect(subject.fetch('bytes_is')).to eq(1000)
    end
  end
end
