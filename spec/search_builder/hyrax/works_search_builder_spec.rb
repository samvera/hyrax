require 'spec_helper'

RSpec.describe Hyrax::WorksSearchBuilder do
  let(:me) { create(:user) }
  let(:config) { CatalogController.blacklight_config }
  let(:scope) do
    double('The scope',
           blacklight_config: config,
           params: {},
           current_ability: Ability.new(me),
           current_user: me)
  end
  let(:builder) { described_class.new(scope) }

  describe "#to_hash" do
    before do
      # This prevents any generated classes from interfering with this test:
      allow(builder).to receive(:work_classes).and_return([GenericWork])

      allow(builder).to receive(:gated_discovery_filters)
        .and_return(["depositor"])
    end

    subject { builder.to_hash['fq'] }

    it "filters works that we are the depositor of" do
      expect(subject).to match_array ["{!terms f=has_model_ssim}GenericWork",
                                      "-suppressed_bsi:true",
                                      "depositor"]
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
        :add_access_controls_to_solr_params,
        :filter_models,
        :only_active_works
      ]
    end
    it { is_expected.to eq expected_filters }
  end
end
