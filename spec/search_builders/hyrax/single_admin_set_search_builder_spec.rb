# frozen_string_literal: true
RSpec.describe Hyrax::SingleAdminSetSearchBuilder do
  let(:ability) { instance_double(Ability, admin?: true) }
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:builder) { described_class.new(context) }

  describe "#query" do
    before do
      expect(builder).to receive(:find_one)
    end
    subject { builder.with(id: '123').query.fetch('fq') }

    it do
      is_expected.to match_array ["",
                                  "{!terms f=has_model_ssim}AdminSet,Hyrax::AdministrativeSet"]
    end
  end
end
