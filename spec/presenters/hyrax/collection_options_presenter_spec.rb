require 'spec_helper'

RSpec.describe Hyrax::CollectionOptionsPresenter do
  let(:instance) { described_class.new(service) }
  let(:doc1) { instance_double(SolrDocument, id: 4, to_s: 'Title 1') }
  let(:doc2) { instance_double(SolrDocument, id: 2, to_s: 'Other Title 1') }
  let(:search_results) { [doc1, doc2] }
  let(:service) { instance_double(Hyrax::CollectionsService, search_results: search_results) }

  describe "#select_options" do
    subject { instance.select_options }
    it { is_expected.to eq [["Other Title 1", 2], ["Title 1", 4]] }
  end
end
