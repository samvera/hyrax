require 'spec_helper'

describe CurationConcerns::CollectionPresenter do
  let(:collection) do
    build(:collection,
          id: 'adc12v',
          description: ['a nice collection'],
          title: ['A clever title'],
          keyword: ['neologism'],
          date_created: ['some date'])
  end
  let(:work) { build(:work, title: ['unimaginitive title']) }
  let(:solr_document) { SolrDocument.new(collection.to_solr) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_document, ability) }

  # Mock bytes so collection does not have to be saved.
  before { allow(collection).to receive(:bytes).and_return(0) }

  describe '#title' do
    subject { presenter.title }
    it { is_expected.to eq ['A clever title'] }
  end

  describe '#keyword' do
    subject { presenter.keyword }
    it { is_expected.to eq ['neologism'] }
  end

  describe '#to_key' do
    subject { presenter.to_key }
    it { is_expected.to eq ['adc12v'] }
  end

  describe "#size" do
    subject { presenter.size }
    it { is_expected.to eq '0 Bytes' }
  end

  describe "#total_items" do
    subject { presenter.total_items }
    context "empty collection" do
      it { is_expected.to eq 0 }
    end
    context "collection with work" do
      before { collection.members << work }
      it { is_expected.to eq 1 }
    end
    context "null members" do
      let(:presenter) { described_class.new({}, nil) }
      it { is_expected.to eq 0 }
    end
  end

  describe "#date_created" do
    subject { presenter.date_created }
    it { is_expected.to eq 'some date' }
  end
end
