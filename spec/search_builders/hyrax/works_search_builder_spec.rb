# frozen_string_literal: true
RSpec.describe Hyrax::WorksSearchBuilder do
  describe "::default_processor_chain" do
    subject { described_class.default_processor_chain }

    let(:blacklight_filters) do
      # These filters are in Blacklight::Solr::SearchBuilderBehavior
      [
        :default_solr_parameters,
        :add_query_to_solr,
        :add_facet_fq_to_solr,
        :add_facetting_to_solr,
        :add_solr_fields_to_query,
        :add_paging_to_solr,
        :add_sorting_to_solr,
        :add_group_config_to_solr,
        :add_facet_paging_to_solr,
        :add_access_controls_to_solr_params
      ]
    end

    it { is_expected.to eq blacklight_filters + [:filter_models] }
  end
end
