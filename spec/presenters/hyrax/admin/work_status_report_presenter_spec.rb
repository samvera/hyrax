RSpec.describe Hyrax::Admin::WorkStatusReportPresenter do
  let(:stats_filters) { double('stats_filters') }
  let(:limit) { double('limit') }
  let(:instance) { described_class.new(stats_filters, limit) }

  describe "current_work_types" do
    subject { instance.current_work_types }

    let(:solr_data) do
      { "facet_counts" => {
        "facet_fields" => { "has_model_ssim" => ["GenericWork", 24, "Book", 7, "Journal", 6] }
      } }
    end
    let(:connection) { instance_double(RSolr::Client) }

    it "returns the works types in the repository" do
      allow(ActiveFedora::SolrService.instance).to receive(:conn).and_return(connection)
      allow(connection).to receive(:get).with("select", params: { fq: '{!terms f=generic_type_sim}Work',
                                                                  'facet.field' => 'has_model_ssim' }).and_return(solr_data)
      expect(subject).to eq ['GenericWork', 'Book', 'Journal']
    end
  end
end
