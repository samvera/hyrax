require 'spec_helper'

describe Hyrax::CollectionIndexer do
  let(:indexer) { described_class.new(collection) }
  let(:collection) { build(:collection) }
  let(:col1id) { 'col1' }
  let(:col2id) { 'col2' }
  let(:col1title) { 'col1 title' }
  let(:col2title) { 'col2 title' }
  let(:col1) { instance_double(Collection, id: col1id, to_s: col1title) }
  let(:col2) { instance_double(Collection, id: col2id, to_s: col2title) }

  describe "#generate_solr_document" do
    before do
      allow(collection).to receive(:bytes).and_return(1000)
      allow(collection).to receive(:in_collections).and_return([col1, col2])

      allow(Hyrax::ThumbnailPathService).to receive(:call).and_return("/downloads/1234?file=thumbnail")
    end
    subject { indexer.generate_solr_document }

    it "has required fields" do
      expect(subject.fetch('generic_type_sim')).to eq ["Collection"]
      expect(subject.fetch('bytes_lts')).to eq(1000)
      expect(subject.fetch('thumbnail_path_ss')).to eq "/downloads/1234?file=thumbnail"
      expect(subject.fetch('member_of_collection_ids_ssim')).to eq [col1id, col2id]
      expect(subject.fetch('member_of_collections_ssim')).to eq [col1title, col2title]
    end
  end
end
