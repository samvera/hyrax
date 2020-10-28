# frozen_string_literal: true
RSpec.describe Hyrax::Admin::RepositoryObjectPresenter do
  let(:instance) { described_class.new }

  describe "#as_json" do
    subject { instance.as_json }

    let(:response) { Blacklight::Solr::Response.new(solr_data, {}) }
    let(:solr_data) do
      { "facet_counts" => {
        "facet_fields" => { "suppressed_bsi" => ["false", 1, "true", 2, nil, 3] }
      } }
    end

    before do
      allow_any_instance_of(Hyrax::SearchService).to receive(:search_results).and_return([response, nil])
    end
    it do
      is_expected.to eq [{ label: "Published", value: 1 },
                         { label: "Unpublished", value: 2 },
                         { label: "Unknown", value: 3 }]
    end
  end
end
