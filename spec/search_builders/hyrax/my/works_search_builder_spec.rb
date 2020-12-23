# frozen_string_literal: true
RSpec.describe Hyrax::My::WorksSearchBuilder do
  subject(:builder) { described_class.new(scope) }
  let(:me) { FactoryBot.create(:user) }
  let(:scope) { FakeSearchBuilderScope.new(current_user: me) }

  describe "#to_hash" do
    before do
      allow(ActiveFedora::SolrQueryBuilder).to receive(:construct_query_for_rel)
        .with(depositor: me.user_key)
        .and_return("depositor")
    end

    it "filters works that we are the depositor of" do
      expect(builder.to_hash['fq'])
        .to contain_exactly start_with("{!terms f=has_model_ssim}"), "depositor"
    end
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    let(:expected_filters) do
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
        :filter_models,
        :show_only_resources_deposited_by_current_user
      ]
    end

    it { is_expected.to eq expected_filters }
  end
end
