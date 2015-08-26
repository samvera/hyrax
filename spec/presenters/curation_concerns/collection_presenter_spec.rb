require 'spec_helper'

describe CurationConcerns::CollectionPresenter do
  let(:collection) { Collection.new(id: 'adc12v', description: 'a nice collection', title: 'A clever title') }
  let(:solr_document) { SolrDocument.new(collection.to_solr) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe '#title' do
    subject { presenter.title }
    it { is_expected.to eq 'A clever title' }
  end

  describe '#to_key' do
    subject { presenter.to_key }
    it { is_expected.to eq ['adc12v'] }
  end
end
