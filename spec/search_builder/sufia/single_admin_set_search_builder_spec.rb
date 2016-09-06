require 'spec_helper'

RSpec.describe Sufia::SingleAdminSetSearchBuilder do
  let(:ability) { instance_double(Ability, admin?: true) }
  let(:context) { double(blacklight_config: CatalogController.blacklight_config,
                         current_ability: ability) }
  let(:builder) { described_class.new(context) }
  describe "#query" do
    subject { builder.with(id: '123').query.fetch('fq') }
    it { is_expected.to match_array ["", "_query_:\"{!field f=has_model_ssim}AdminSet\"", "_query_:\"{!field f=id}123\""] }
  end
end
