RSpec.describe Hyrax::Admin::RepositoryObjectPresenter do
  let(:instance) { described_class.new }

  describe "#as_json" do
    subject { instance.as_json }

    let(:stub_repo) { double(search: response) }
    let(:response) { Blacklight::Solr::Response.new(solr_data, {}) }
    let(:solr_data) do
      { "facet_counts" => {
        "facet_fields" => { "suppressed_bsi" => ["false", 1, "true", 2, nil, 3] }
      } }
    end

    before do
      allow(instance).to receive(:repository).and_return(stub_repo)
    end
    it do
      is_expected.to eq [["Published", 1],
                         ["Unpublished", 2],
                         ["Unknown", 3]]
    end
  end
end
