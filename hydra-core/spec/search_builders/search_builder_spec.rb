require 'spec_helper'

describe SearchBuilder do
  let(:processor_chain) { [:add_access_controls_to_solr_params] }
  let(:context) { double('context') }
  let(:user) { double('user', user_key: 'joe') }
  let(:current_ability) { double('ability', user_groups: [], current_user: user) }
  let(:search_builder) { described_class }

  subject do
    search_builder.new(processor_chain, context)
  end

  it "extends classes with the necessary Hydra modules" do
    expect(described_class.included_modules).to include(Hydra::AccessControlsEnforcement)
  end

  context "when a query is generated" do
    it "triggers add_access_controls_to_solr_params" do
      expect(subject).to receive(:add_access_controls_to_solr_params)
      subject.query
    end
  end
end
