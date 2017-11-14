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

  describe '#by_depositor' do
    let(:context) do
      double(blacklight_config: CatalogController.blacklight_config,
             current_ability: ability)
    end
    let(:ability) do
      instance_double(Ability, admin?: true)
    end
    let(:instance) { described_class.new(described_class.default_processor_chain + [:by_depositor], context) }
    let(:depositor) { "joe@example.com" }

    subject { instance.with(depositor: depositor).query }

    it 'adds a fq' do
      expect(subject['fq']).to include "{!field f=depositor_ssim v=joe@example.com}"
    end
  end
end
