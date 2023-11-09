# frozen_string_literal: true

RSpec.shared_examples "a total_viewable method" do
  context('empty collection') { it { is_expected.to eq 0 } }

  context "null members" do
    let(:presenter) { described_class.new(SolrDocument.new(id: '123'), ability) }

    it { is_expected.to eq 0 }
  end
end

RSpec.shared_examples "a collection with public work and sub-collection" do
  context "collection with public work and sub-collection" do
    let!(:work) { create(:public_work, member_of_collections: [collection]) }
    let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

    it { is_expected.to eq 1 }
  end
end

RSpec.shared_examples "a collection with public collection" do
  context "collection with public collection" do
    let!(:subcollection) { create(:public_collection_lw, member_of_collections: [collection]) }

    it { is_expected.to eq 1 }
  end
end

RSpec.shared_examples "a collection with public work" do
  context "collection with public work" do
    let!(:work) { create(:public_work, member_of_collections: [collection]) }

    it { is_expected.to eq 1 }
  end
end

RSpec.shared_examples "a collection with private work" do
  context "collection with private work" do
    let!(:work) { create(:private_work, member_of_collections: [collection]) }

    it { is_expected.to eq 0 }
  end
end
