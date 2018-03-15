RSpec.describe Hyrax::AnalyticsWorksSearchBuilder do
  let(:context) { double }

  describe '::default_processor_chain' do
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
        :add_access_controls_to_solr_params,
        :filter_models
      ]
    end

    it { is_expected.to eq blacklight_filters + [:filter_search] }
  end

  describe 'empty filter_search' do
    let(:solr_params) { { fq: [] } }
    let(:search_builder) { described_class.new(context, search: { value: '' }) }
    before { search_builder.filter_search(solr_params) }

    it 'does nothing if no params are passed' do
      expect(solr_params[:fq]).to eq []
    end
  end

  describe 'filter_search with search text' do
    let(:wildcard_param) { '/.*test.*/' }
    let(:query) { ['test', "(title_tesim:#{wildcard_param} OR date_created_tesim:#{wildcard_param} OR visibility_ssi:#{wildcard_param} OR human_readable_type_tesim:#{wildcard_param})"] }
    let(:search_builder) { described_class.new(context, search: { value: 'test' }) }
    let(:solr_params) { { fq: ['test'] } }
    before { search_builder.filter_search(solr_params) }

    it 'if params are passed' do
      expect(solr_params[:fq]).to eq query
    end
  end
end
