# frozen_string_literal: true
RSpec.describe Hyrax::My::SharesSearchBuilder do
  subject(:builder) { described_class.new(scope) }
  let(:me) { FactoryBot.create(:user) }
  let(:scope) { FakeSearchBuilderScope.new(current_user: me) }

  before do
    allow(ActiveFedora::SolrQueryBuilder).to receive(:construct_query_for_rel)
      .with(depositor: me.user_key)
      .and_return("depositor")
  end

  it "filters things we have access to in which we are not the depositor" do
    gated_access = builder.gated_discovery_filters.join(' OR ')

    expect(builder.to_hash['fq'])
      .to contain_exactly(gated_access, include('Collection'), "-suppressed_bsi:true", "-depositor")
  end
end
