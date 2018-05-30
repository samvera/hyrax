RSpec.describe Hyrax::CollectionsCountService do
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

    let(:access) { :edit }
    let(:documents) { [doc1, doc2] }
    let(:doc1) { SolrDocument.new(id: 'xyz123') }
    let(:doc2) { SolrDocument.new(id: 'yyx123') }
    let(:connection) { instance_double(RSolr::Client) }
    let(:facets) { { 'member_of_collection_ids_ssim' => [doc1.id, 8, doc2.id, 2] } }
    let(:document_list) do
      [
        {
          'member_of_collection_ids_ssim' => ['xyz123'],
          'member_of_collections_ssim' => ['xyz123'],
          'file_set_ids_ssim' => ['aaa', 'bbb', 'ccc'],
          'system_modified_dtsi' => '2015-01-01T20:50:35Z',
          'title_tesim' => ['xyz123']
        },
        {
          'member_of_collection_ids_ssim' => ['yyx123'],
          'member_of_collections_ssim' => ['yyx123'],
          'file_set_ids_ssim' => ['bbb', 'ccc'],
          'system_modified_dtsi' => '2015-02-01T20:50:35Z',
          'title_tesim' => ['yyx123']
        }
      ]
    end

    let(:results) do
      {
        'response' =>
        {
          'docs' => document_list
        },
        'facet_counts' =>
        {
          'facet_fields' => facets
        }
      }
    end

    let(:struct) { described_class::SearchResultForWorkCount }

    before do
      allow(service).to receive(:search_results).and_return(documents)
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(connection).to receive(:get).with("select", params: { fq: "{!terms f=member_of_collection_ids_ssim}xyz123,yyx123",
                                                                  "facet.field" => "member_of_collection_ids_ssim" }).and_return(results)
    end

    context "when there are works in the collection" do
      it "returns rows with document in the first column, last modified in the second column and integer count values in the third and fourth column" do
        expect(subject).to eq [struct.new(doc1, '2015-01-01', 8, 3, doc1.id), struct.new(doc2, '2015-02-01', 2, 2, doc2.id)]
      end
    end

    context "when there are no files in the collection" do
      let(:document_list) do
        [
          {
            'member_of_collection_ids_ssim' => ['xyz123'],
            'member_of_collections_ssim' => ['xyz123'],
            'title_tesim' => ['xyz123']
          },
          {
            'member_of_collection_ids_ssim' => ['xyz123', 'yyx123'],
            'member_of_collections_ssim' => ['xyz123', 'yyx123'],
            'title_tesim' => ['yyx123']
          }
        ]
      end

      it "returns rows with document in the first column no date in the second column and integer count values in the third and fourth column" do
        expect(subject).to eq [struct.new(doc1, nil, 8, 0, doc1.id), struct.new(doc2, nil, 2, 0, doc2.id)]
      end
    end
  end
end
