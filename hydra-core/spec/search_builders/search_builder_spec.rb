require 'spec_helper'

describe Hydra::AccessControls::SearchBuilder do
  let(:config) { CatalogController.blacklight_config }
  let(:context) { double('context', blacklight_config: config) }
  let(:user) { double('user', user_key: 'joe') }
  let(:current_ability) do
    double('ability', user_groups: [], current_user: user)
  end

  let(:search_builder) { described_class }

  subject do
    search_builder.new(context, ability: current_ability)
  end

  context "when a query is generated" do
    it "triggers add_access_controls_to_solr_params" do
      expect(subject).to receive(:apply_gated_discovery)
      subject.query
    end
  end
end
