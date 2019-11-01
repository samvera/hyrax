# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieIndexer do
  let(:indexer) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_resource) }

  describe '.for' do
    it 'creates an instance of itself as the default indexer class' do
      expect(described_class.for(resource: Valkyrie::Resource.new).class)
        .to eq described_class
    end
  end

  describe "#to_solr" do
    it "provides id, created_at_dtsi, and updated_at_dtsi" do
      expect(indexer.to_solr).to match a_hash_including(
        id: resource.id.to_s,
        created_at_dtsi: resource.created_at,
        updated_at_dtsi: resource.updated_at
      )
    end
  end
end
