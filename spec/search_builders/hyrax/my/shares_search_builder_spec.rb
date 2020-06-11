# frozen_string_literal: true
RSpec.describe Hyrax::My::SharesSearchBuilder do
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

  before do
    allow(builder).to receive(:gated_discovery_filters).and_return(["access_filter1", "access_filter2"])

    # This prevents any generated classes from interfering with this test:
    allow(builder).to receive(:work_classes).and_return([GenericWork])

    allow(ActiveFedora::SolrQueryBuilder).to receive(:construct_query_for_rel)
      .with(depositor: me.user_key)
      .and_return("depositor")
  end

  subject { builder.to_hash['fq'] }

  it "filters things we have access to in which we are not the depositor" do
    expect(subject).to eq ["access_filter1 OR access_filter2",
                           "{!terms f=has_model_ssim}GenericWork,Collection",
                           "-suppressed_bsi:true",
                           "-depositor"]
  end
end
