require 'spec_helper'

describe CurationConcerns::CollectionIndexer do
  let(:indexer) { described_class.new(collection) }
  let(:collection) { build(:collection) }

  describe "#generate_solr_document" do
    subject { indexer.generate_solr_document }

    it "has generic type" do
      expect(subject.fetch('generic_type_sim')).to eq ["Collection"]
    end
  end
end
