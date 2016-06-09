describe Sufia::MySharesSearchBuilder do
  let(:me) { create(:user) }
  let(:config) { CatalogController.blacklight_config }
  let(:scope) { double('The scope',
                       blacklight_config: config,
                       params: {},
                       current_ability: Ability.new(me),
                       current_user: me) }
  let(:builder) { described_class.new(scope) }

  before { allow(builder).to receive(:gated_discovery_filters).and_return(["access_filter1", "access_filter2"]) }

  subject { builder.to_hash['fq'] }

  it "filters things we have access to in which we are not the depositor" do
    expect(subject).to eq ["access_filter1 OR access_filter2",
                           "{!terms f=has_model_ssim}GenericWork,Collection",
                           "-_query_:\"{!field f=depositor_ssim}#{me.email}\""]
  end
end
