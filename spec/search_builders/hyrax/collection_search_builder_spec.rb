RSpec.describe Hyrax::CollectionSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:ability) do
    instance_double(Ability, admin?: true)
  end
  let(:instance) { described_class.new(context) }

  describe "#only_collections?" do
    subject { instance.send(:only_collections?) }

    it { is_expected.to be true }
  end

  describe "::default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include(:filter_models) }
  end

  describe '#by_depositor' do
    let(:instance) { described_class.new(described_class.default_processor_chain + [:by_depositor], context) }
    let(:depositor) { "joe@example.com" }

    subject { instance.with(depositor: depositor).query }

    it 'adds a fq' do
      expect(subject['fq']).to include "{!field f=depositor_ssim v=joe@example.com}"
    end
  end
end
