RSpec.describe Hyrax::WorksCountService do
  let(:controller) { ::CatalogController.new }
  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end
  let(:service) { described_class.new(context) }
  let(:user) { create(:user) }

  context "with injection" do
    subject { service.search_results(access) }

    let(:service) { described_class.new(context, search_builder) }
    let(:access) { :edit }
    let(:search_builder) { double(new: search_builder_instance) }
    let(:search_builder_instance) { double }

    it "calls the injected search builder" do
      expect(search_builder_instance).to receive(:rows).and_return(search_builder_instance)
      expect(search_builder_instance).to receive(:reverse_merge).and_return({})
      subject
    end
  end

  describe '#search_results_with_work_count' do
    subject { service.search_results_with_work_count(access) }

    let(:access) { :edit}
    let(:documents) { [doc1, doc2] }
    let(:doc1) { SolrDocument.new(id: 'xyz123',  human_readable_type_tesim: ['Work type'],
                                  visibility_ssi: 'restricted',
                                  system_create_dtsi: '2015-01-01T20:50:35Z') }
    let(:doc2) { SolrDocument.new(id: 'yyx123',  human_readable_type_tesim: ['Work type'],
                                  visibility_ssi: 'institution',
                                  system_create_dtsi: '2015-02-01T20:50:35Z') }


    let(:struct) { described_class::SearchResultForWorkCount }

    before do
      allow(service).to receive(:search_results).and_return(documents)
    end

    context "when there are works in the collection" do
      it "returns rows with document in the first column, last modified in the second column and integer count values in the third and fourth column" do
        expect(subject).to eq [struct.new(doc1, '2015-01-01', 0, 'Work type', 'restricted'), struct.new(doc2, '2015-02-01', 0, 'Work type', 'institution')]
      end
    end
  end
end
