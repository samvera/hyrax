RSpec.describe Hyrax::CollectionMemberSearchBuilder do
  let(:context) { double("context", blacklight_config: CatalogController.blacklight_config) }
  let(:solr_params) { { fq: [] } }
  let(:include_models) { :both }
  let(:builder) { described_class.new(context, search_includes_models: include_models) }

  describe ".default_processor_chain" do
    subject { builder.default_processor_chain }

    it { is_expected.to include :member_of_collection }
  end

  describe '#member_of_collection' do
    let(:collection) { build(:collection, id: '12345') }
    let(:subject) { builder.member_of_collection(solr_params) }

    it 'updates solr_parameters[:fq]' do
      allow(context).to receive(:collection).and_return(collection)
      subject
      expect(solr_params[:fq]).to include("#{builder.collection_membership_field}:#{collection.id}")
    end
  end

  describe '#models' do
    let(:work_classes) { [GenericWork, RareBooks::Atlas] }
    let(:collection_classes) { [Collection] }
    let(:subject) { builder.models }

    context 'when search_include_models: :works' do
      let(:include_models) { :works }

      it 'returns only work members' do
        expect(subject).to eq(Hyrax.config.curation_concerns)
      end
    end

    context 'when search_include_models: :collections' do
      let(:include_models) { :collections }

      it 'returns only collection members' do
        expect(subject).to eq(collection_classes)
      end
    end

    context 'when search_include_models anything else' do
      let(:search_includes_models) { "anything" }

      it 'returns both work and collection members' do
        expect(subject).to include(*work_classes)
        expect(subject).to include(*collection_classes)
      end
    end
  end
end
