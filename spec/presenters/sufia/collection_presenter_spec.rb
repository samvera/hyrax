require 'spec_helper'

describe Sufia::CollectionPresenter do
  describe ".terms" do
    subject { described_class.terms }
    it { is_expected.to eq [:title, :total_items, :size, :resource_type, :description, :creator,
                            :contributor, :keyword, :rights, :publisher, :date_created, :subject,
                            :language, :identifier, :based_near, :related_url] }
  end

  let(:collection) { build(:collection,
                           description: ['a nice collection'],
                           based_near: ['Over there'],
                           title: ['A clever title'],
                           resource_type: ['Collection'],
                           related_url: ['http://example.com/']) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  describe "#resource_type" do
    subject { presenter.resource_type }
    it { is_expected.to eq ['Collection'] }
  end

  describe "#terms_with_values" do
    subject { presenter.terms_with_values }
    it { is_expected.to eq [:title,
                            :total_items,
                            :size,
                            :resource_type,
                            :description,
                            :based_near,
                            :related_url] }
  end

  describe "#title" do
    subject { presenter.title }
    it { is_expected.to eq ['A clever title'] }
  end

  describe "#based_near" do
    subject { presenter.based_near }
    it { is_expected.to eq ['Over there'] }
  end

  describe "#related_url" do
    subject { presenter.related_url }
    it { is_expected.to eq ['http://example.com/'] }
  end

  describe "#size" do
    subject { presenter.size }
    it { is_expected.to eq '0 Bytes' }
  end

  describe "#total_items" do
    subject { presenter.total_items }
    it { is_expected.to eq 0 }
  end

  subject { presenter }
  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
end
