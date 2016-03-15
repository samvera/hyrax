require 'spec_helper'

describe CurationConcerns::CollectionIndexer do
  let(:indexer) { described_class.new(collection) }
  let(:collection) { build(:collection) }

  describe "#generate_solr_document" do
    before do
      allow(collection).to receive(:bytes).and_return(1000)
      allow(CurationConcerns::ThumbnailPathService).to receive(:call).and_return("/downloads/1234?file=thumbnail")
    end
    subject { indexer.generate_solr_document }

    it "has required fields" do
      expect(subject.fetch('generic_type_sim')).to eq ["Collection"]
      expect(subject.fetch('bytes_lts')).to eq(1000)
      expect(subject.fetch('thumbnail_path_ss')).to eq "/downloads/1234?file=thumbnail"
    end
  end
end
