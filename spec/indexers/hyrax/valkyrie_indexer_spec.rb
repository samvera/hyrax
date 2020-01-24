# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieIndexer do
  let(:indexer) { described_class.new(resource: resource) }

  describe '.for' do
    it 'gives an instance of itself as the default indexer class' do
      expect(described_class.for(resource: Valkyrie::Resource.new).class)
        .to eq described_class
    end

    context 'with a registered indexer' do
      before do
        described_class.register indexer_class, as_indexer_for: work_class
      end

      let(:indexer_class) { Class.new(described_class) }
      let(:work_class)    { Class.new(Hyrax::Work) }

      it 'gives an instance of Hyrax::ValkyrieWorkIndexer for Work' do
        expect(described_class.for(resource: work_class.new))
          .to be_a indexer_class
      end
    end

    # Fails unless MonographIndexer has been pre-loaded
    context 'with registered Monograph indexer' do
      let(:resource) { build(:monograph) }
      let(:indexer_class) { MonographIndexer }

      it 'gives an instance of MonographIndexer for Monograph' do
        expect(described_class.for(resource: resource))
          .to be_a indexer_class
      end
    end
  end

  describe "#to_solr" do
    let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }

    it "provides id, created_at_dtsi, and updated_at_dtsi" do
      expect(indexer.to_solr).to match a_hash_including(
        id: resource.id.to_s,
        created_at_dtsi: resource.created_at,
        updated_at_dtsi: resource.updated_at
      )
    end
  end
end
