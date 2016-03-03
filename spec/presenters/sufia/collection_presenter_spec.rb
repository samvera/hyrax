require 'spec_helper'

describe Sufia::CollectionPresenter do
  describe ".terms" do
    subject { described_class.terms }
    it { is_expected.to eq [:title, :total_items, :size, :resource_type, :description, :creator,
                            :contributor, :tags, :rights, :publisher, :date_created, :subject,
                            :language, :identifier, :based_near, :related_url] }
  end

  let(:collection) { build(:collection, id: '111', description: ['a nice collection'], title: ['A clever title'], resource_type: ['Collection']) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  describe "#resource_type" do
    subject { presenter.resource_type }
    it { is_expected.to eq ['Collection'] }
  end

  describe "#terms_with_values" do
    subject { presenter.terms_with_values }
    it { is_expected.to eq [:title, :total_items, :size, :resource_type, :description] }
  end

  describe "#title" do
    subject { presenter.title }
    it { is_expected.to eq 'A clever title' }
  end

  describe "#size" do
    subject { presenter.size }
    it { is_expected.to eq '0 Bytes' }
  end

  describe "#total_items" do
    subject { presenter.total_items }
    it { is_expected.to eq 0 }
  end
end
