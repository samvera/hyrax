require 'spec_helper'

describe Hydra::SearchBuilder do
  let(:processor_chain) { [:add_access_controls_to_solr_params] }
  let(:context) { double('context') }
  let(:user) { double('user', user_key: 'joe') }
  let(:current_ability) { double('ability', user_groups: [], current_user: user) }

  subject { described_class.new(processor_chain, context) }
  before { subject.current_ability = current_ability }

  it "should extend classes with the necessary Hydra modules" do
    expect(Hydra::SearchBuilder.included_modules).to include(Hydra::AccessControlsEnforcement)
  end

  context "when a query is generated" do
    it "should triggers add_access_controls_to_solr_params" do
      expect(subject).to receive(:add_access_controls_to_solr_params)
      subject.query
    end
  end
end
