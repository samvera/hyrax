describe Sufia::MySharesSearchBuilder do
  let(:me) { create(:user) }
  let(:config) { CatalogController.blacklight_config }
  let(:scope) { double('The scope',
                       blacklight_config: config,
                       params: {},
                       current_user: me) }
  let(:builder) { described_class.new(scope) }

  before do
    builder.current_ability = Ability.new(me)
  end

  subject { builder.to_hash['fq'] }

  it "filters things we have access to in which we are not the depositor" do
    expect(subject).to eq ["edit_access_group_ssim:public OR edit_access_group_ssim:registered OR edit_access_person_ssim:#{me.user_key}",
                           "(_query_:\"{!field f=has_model_ssim}GenericWork\" OR _query_:\"{!field f=has_model_ssim}Collection\")",
                           "-_query_:\"{!field f=depositor_ssim}#{me.user_key}\""]
  end
end
