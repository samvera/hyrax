RSpec.describe Hyrax::WorksCountService do
  let(:controller) { ::CatalogController.new }
  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end
  let(:params) { { draw: 1, start: 0, length: 10, order: { '0' => { dir: 'asc', column: 0 } } } }
  let(:search_builder_instance) { double }
  let(:search_builder) { double(new: search_builder_instance) }
  let(:service) { described_class.new(context, search_builder, params) }
  let(:user) { create(:user) }

  context 'with injection' do
    subject { service.search_results(access) }

    let(:access) { :edit }
    let(:search_builder) { double(new: search_builder_instance) }
    let(:search_builder_instance) { double }

    it 'calls the injected search builder' do
      expect(search_builder_instance).to receive(:rows).and_return(search_builder_instance)
      expect(search_builder_instance).to receive(:reverse_merge).and_return({})
      subject
    end
  end

  describe '#search_results_with_work_count' do
    subject { service.search_results_with_work_count(access) }

    let(:access) { :edit }
    let(:documents) { [doc1, doc2] }
    let(:connection) { instance_double(RSolr::Client) }
    let(:doc1) do
      SolrDocument.new(id: 'xyz123',
                       title_tesim: ['test1'],
                       human_readable_type_tesim: ['Work type'],
                       visibility_ssi: 'restricted',
                       system_create_dtsi: '2015-01-01T20:50:35Z')
    end
    let(:doc2) do
      SolrDocument.new(id: 'yyx123',
                       human_readable_type_tesim: ['Work type'],
                       title_tesim: ['test2'],
                       visibility_ssi: 'institution',
                       system_create_dtsi: '2015-02-01T20:50:35Z')
    end

    let(:results) do
      {
        'response' =>
            {
              'docs' => documents,
              'numFound' => 2
            }
      }
    end

    before do
      allow(service).to receive(:search_results).and_return(documents)
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(connection).to receive(:get).with('select', params: { fq: '{!terms f=has_model_ssim}GenericWork',
                                                                  rows: 10 }).and_return(results)
    end

    context 'when there are works in the collection' do
      it 'returns rows with document name, created date, usage count, work type, and visibility' do
        expect(subject).to include(
          draw: 1,
          recordsTotal: 2,
          recordsFiltered: 2,
          data: [['test1', '2015-01-01', 0, 'Work type', 'restricted'], ['test2', '2015-02-01', 0, 'Work type', 'institution']]
        )
      end
    end
  end
end
