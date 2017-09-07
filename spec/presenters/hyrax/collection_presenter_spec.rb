RSpec.describe Hyrax::CollectionPresenter do
  describe ".terms" do
    subject { described_class.terms }

    it do
      is_expected.to eq [:total_items, :size, :resource_type, :creator,
                         :contributor, :keyword, :license, :publisher,
                         :date_created, :subject, :language, :identifier,
                         :based_near, :related_url]
    end
  end

  let(:collection) do
    build(:collection,
          id: 'adc12v',
          description: ['a nice collection'],
          based_near: ['Over there'],
          title: ['A clever title'],
          keyword: ['neologism'],
          resource_type: ['Collection'],
          related_url: ['http://example.com/'],
          date_created: ['some date'])
  end
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  # Mock bytes so collection does not have to be saved.
  before { allow(collection).to receive(:bytes).and_return(0) }

  describe "collection type methods" do
    subject { presenter }

    it { is_expected.to delegate_method(:collection_type_is_nestable?).to(:collection_type).as(:nestable?) }
    it { is_expected.to delegate_method(:collection_type_is_discoverable?).to(:collection_type).as(:discoverable?) }
    it { is_expected.to delegate_method(:collection_type_is_sharable?).to(:collection_type).as(:sharable?) }
    it { is_expected.to delegate_method(:collection_type_is_allow_multiple_membership?).to(:collection_type).as(:allow_multiple_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_require_membership?).to(:collection_type).as(:require_membership?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_workflow?).to(:collection_type).as(:assigns_workflow?) }
    it { is_expected.to delegate_method(:collection_type_is_assigns_visibility?).to(:collection_type).as(:assigns_visibility?) }
  end

  # NOTE: The #collection_type specs will change when we go to integrate PR 1556 (https://github.com/samvera/hyrax/pull/1556)
  describe '#collection_type', clean_repo: true do
    let(:collection_type) { create(:collection_type) }

    describe 'when solr_document#collection_type_gid exists' do
      let(:collection) { build(:collection, collection_type_gid: collection_type.gid) }
      let(:solr_doc) { SolrDocument.new(collection.to_solr) }

      it 'finds the collection type based on the solr_document#collection_type_gid if one exists' do
        expect(solr_doc.key?('collection_type_gid_ssim')).to be_truthy
        expect(solr_doc).to receive(:fetch).with('collection_type_gid_ssim').and_return(collection_type.gid)
        expect(presenter.collection_type).to eq(collection_type)
      end
    end

    describe 'when solr_document#collection_type_gid does not exist' do
      let(:solr_doc) { SolrDocument.new(collection.to_solr.except('collection_type_gid_ssim')) }

      describe 'and underlying Fedora object has a collection_type_gid' do
        let(:collection) { create(:collection, collection_type_gid: collection_type.gid) }

        it "finds the collection's collection type of the solr document's id if the document does not have a collection_type_gid" do
          expect(solr_doc).not_to receive(:collection_type_gid)
          expect(presenter.collection_type).to eq(collection_type)
        end
      end

      describe 'and underlying Fedora object does not have a collection_type_gid' do
        let(:collection) { create(:typeless_collection) }

        it "finds the find_or_create_default_collection_type" do
          expect(collection.collection_type_gid).to be_nil # Verifying that I don't have a collection_type from my factory
          expect(solr_doc).not_to receive(:collection_type_gid)
          expect(presenter.collection_type).to eq(Hyrax::CollectionType.find_or_create_default_collection_type)
        end
      end
    end
  end

  describe "#resource_type" do
    subject { presenter.resource_type }

    it { is_expected.to eq ['Collection'] }
  end

  describe "#terms_with_values" do
    subject { presenter.terms_with_values }

    it do
      is_expected.to eq [:total_items,
                         :size,
                         :resource_type,
                         :keyword,
                         :date_created,
                         :based_near,
                         :related_url]
    end
  end

  describe '#to_s' do
    subject { presenter.to_s }

    it { is_expected.to eq 'A clever title' }
  end

  describe "#title" do
    subject { presenter.title }

    it { is_expected.to eq ['A clever title'] }
  end

  describe '#keyword' do
    subject { presenter.keyword }

    it { is_expected.to eq ['neologism'] }
  end

  describe "#based_near" do
    subject { presenter.based_near }

    it { is_expected.to eq ['Over there'] }
  end

  describe "#related_url" do
    subject { presenter.related_url }

    it { is_expected.to eq ['http://example.com/'] }
  end

  describe '#to_key' do
    subject { presenter.to_key }

    it { is_expected.to eq ['adc12v'] }
  end

  describe "#size", :clean_repo do
    subject { presenter.size }

    it { is_expected.to eq '0 Bytes' }
  end

  describe "#total_items", :clean_repo do
    subject { presenter.total_items }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with work" do
      let(:work) { create(:work, title: ['unimaginitive title']) }

      before do
        work.member_of_collections << collection
        work.save!
      end

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it { is_expected.to eq 0 }
    end
  end

  subject { presenter }

  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }
end
