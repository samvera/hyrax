RSpec.describe Hyrax::Stats::ResourceTypeSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:ability) do
    instance_double(Ability, admin?: true)
  end
  let(:instance) { described_class.new(context) }

  describe "#query" do
    subject { instance.query }

    it "sets required parameters" do
      expect(subject['facet.field']).to eq ["resource_type_tesim"]
      expect(subject['facet.missing']).to eq true
      expect(subject['rows']).to eq 0
    end
  end

  describe "#only_works?" do
    subject { instance.send(:only_works?) }

    it { is_expected.to be true }
  end

  describe "::default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include(:filter_models) }
  end
end