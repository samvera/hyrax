# frozen_string_literal: true
RSpec.describe Hyrax::Stats::WorkStatusSearchBuilder do
  subject(:instance) { described_class.new(context) }

  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end

  let(:ability) do
    instance_double(Ability, admin?: true)
  end

  describe "#query" do
    it "sets required parameters" do
      expect(instance.query['facet.field']).to eq ["suppressed_bsi"]
      expect(instance.query['facet.missing']).to eq true
      expect(instance.query['rows']).to eq 0
    end
  end

  describe "#only_works?" do
    it { expect(instance.send(:only_works?)).to be true }
  end

  describe "::default_processor_chain" do
    it { expect(described_class.default_processor_chain).to include(:filter_models) }
  end
end
