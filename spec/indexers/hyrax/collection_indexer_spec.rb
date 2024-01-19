# frozen_string_literal: true

# Marked as AF-only, since Valkyrie Collection indexing is handled by Hyrax::PcdmCollectionIndexer.
RSpec.describe Hyrax::CollectionIndexer, :active_fedora do
  let(:indexer) { described_class.new(collection) }
  let(:collection) { build(:collection_lw) }
  let(:col1id) { 'col1' }
  let(:col2id) { 'col2' }
  let(:col1title) { 'col1 title' }
  let(:col2title) { 'col2 title' }
  let(:col1) { instance_double(Collection, id: col1id, to_s: col1title) }
  let(:col2) { instance_double(Collection, id: col2id, to_s: col2title) }
  let(:doc) do
    {
      'generic_type_sim' => ['Collection'],
      'thumbnail_path_ss' => '/downloads/1234?file=thumbnail',
      'member_of_collection_ids_ssim' => [col1id, col2id],
      'member_of_collections_ssim' => [col1title, col2title],
      'visibility_ssi' => 'restricted'
    }
  end

  describe "#generate_solr_document" do
    before do
      allow(collection).to receive(:in_collections).and_return([col1, col2])
      allow(Hyrax::ThumbnailPathService).to receive(:call).and_return("/downloads/1234?file=thumbnail")
    end

    context 'without block' do
      subject { indexer.generate_solr_document }

      it "has required fields" do
        expect(subject).to match a_hash_including(doc)
      end
    end

    context 'with block' do
      it 'yields the document that includes our fields' do
        pending 'ActiveFedora pattern must become extensible'
        expect { |b| indexer.generate_solr_document(&b) }.to yield_with_args(a_hash_including(doc))
      end
    end
  end
end
