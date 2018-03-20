RSpec.describe Hyrax::Admin::RepositoryObjectPresenter do
  let(:instance) { described_class.new }
  let(:stub_repo) { double(search: response) }
  let(:response) { Blacklight::Solr::Response.new(solr_data, {}) }
  let(:solr_data) do
    { "facet_counts" => {
        "facet_fields" => { "suppressed_bsi" => ["false", 1, "true", 2, nil, 3] }
    } }
  end

  describe "#as_json_works" do
    subject { instance.as_json }

    before do
      allow(instance).to receive(:repository).and_return(stub_repo)
    end
    it do
      is_expected.to eq [["Published", 1],
                         ["Unpublished", 2],
                         ["Unknown", 3]]
    end
  end

  describe "#as_json_visibility" do
    let(:solr_data) do
      { "facet_counts" => {
          "facet_fields" => { "visibility_ssi" => ["open", 1, "restricted", 2, "authenticated", 3] }
      } }
    end
    let(:instance) { described_class.new('visibility') }
    subject { instance.as_json }

    before do
      allow(instance).to receive(:repository).and_return(stub_repo)
    end
    it do
      is_expected.to eq [["Open", 1],
                         ["Restricted", 2],
                         ["Authenticated", 3]]
    end
  end
end
