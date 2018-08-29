RSpec.describe Hyrax::SingleAdminSetSearchBuilder do
  let(:ability) { instance_double(Ability, admin?: true) }
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:builder) { described_class.new(context) }

  describe "#query" do
    subject { builder.with(id: '123').query.fetch('fq') }
    it { is_expected.to match_array ["", "{!raw f=id}123"] }
  end
end
