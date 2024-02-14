# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Indexers::ResourceIndexer do
  let(:indexer_class) { described_class }
  let(:resource) { FactoryBot.build(:hyrax_work) }
  let(:indexer) { described_class.new(resource: resource) }

  it_behaves_like 'a Hyrax::Resource indexer'

  describe '.for' do
    it 'gives an instance of itself as the default indexer class' do
      expect(described_class.for(resource: Valkyrie::Resource.new).class)
        .to eq described_class
    end

    context 'for a work' do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }

      it 'gives an instance of Hyrax::Indexers::PcdmObjectIndexer' do
        expect(described_class.for(resource: resource))
          .to be_a Hyrax::Indexers::PcdmObjectIndexer
      end
    end

    context 'for a collection' do
      let(:resource) { build(:hyrax_collection) }

      it 'gives an instance of PcdmCollectionIndexer' do
        expect(described_class.for(resource: resource))
          .to be_a Hyrax::Indexers::PcdmCollectionIndexer
      end
    end

    context 'for a Hyrax::FileSet' do
      let(:resource) { build(:hyrax_file_set) }

      it 'gives an instance of ValkyrieFileSetIndexer' do
        expect(described_class.for(resource: resource))
          .to be_a Hyrax::Indexers::FileSetIndexer
      end
    end

    context 'with a matching indexer by naming convention' do
      let(:resource) { build(:monograph) }
      let(:indexer_class) { MonographIndexer }

      it 'gives an instance of MonographIndexer for Monograph' do
        expect(described_class.for(resource: resource))
          .to be_a indexer_class
      end

      context 'and resource was converted using wings' do
        let(:resource) { valkyrie_create(:monograph) }

        it 'gives an instance of MonographIndexer for Monograph' do
          expect(described_class.for(resource: resource))
            .to be_a indexer_class
        end
      end
    end
  end

  describe "#to_solr" do
    let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }

    it "provides indifferent access" do
      expect(indexer.to_solr).to be_a HashWithIndifferentAccess
    end

    it "provides id, date_uploaded_dtsi, and date_modified_dtsi" do
      expect(indexer.to_solr).to match a_hash_including(
        id: resource.id.to_s,
        date_uploaded_dtsi: resource.created_at,
        date_modified_dtsi: resource.updated_at,
        system_create_dtsi: resource.created_at,
        system_modified_dtsi: resource.updated_at
      )
    end
  end
end
