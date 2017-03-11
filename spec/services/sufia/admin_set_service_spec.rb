require 'spec_helper'

RSpec.describe Sufia::AdminSetService, :no_clean do
  let(:controller) { ::CatalogController.new }
  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end
  let(:service) { described_class.new(context) }
  let(:user) { create(:user) }

  describe '#search_results_with_work_count' do
    let(:access) { :read }
    subject { service.search_results_with_work_count(access) }
    let(:documents) { [doc1, doc2, doc3] }
    let(:doc1) { SolrDocument.new(id: 'xyz123') }
    let(:doc2) { SolrDocument.new(id: 'yyx123') }
    let(:doc3) { SolrDocument.new(id: 'zxy123') }
    let(:connection) { instance_double(RSolr::Client) }
    let(:results) do
      { 'facet_counts' =>
        {
          'facet_fields' =>
            {
              'isPartOf_ssim' => [doc1.id, 8, doc2.id, 2]
            }
        } }
    end

    before do
      allow(service).to receive(:search_results).and_return(documents)
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(connection).to receive(:get).with("select", params: { fq: "{!terms f=isPartOf_ssim}xyz123,yyx123,zxy123",
                                                                  "facet.field" => "isPartOf_ssim" }).and_return(results)
    end

    it "returns rows with document in the first column and count in the second column" do
      expect(subject).to eq [[doc1, 8], [doc2, 2], [doc3, nil]]
    end
  end
end
