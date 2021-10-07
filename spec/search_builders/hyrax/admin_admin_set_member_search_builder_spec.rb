# frozen_string_literal: true
RSpec.describe Hyrax::AdminAdminSetMemberSearchBuilder do
  subject(:builder) { described_class.new(scope: scope, collection: admin_set) }
  let(:ability) { Ability.new(user) }
  let(:admin_set) { :FAKE_ADMIN_SET }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: ability) }
  let(:user) { FactoryBot.build(:user) }

  let(:solr_params) { { fq: [] } }

  describe '#filter_models' do
    before { allow(Hyrax.config).to receive(:curation_concerns).and_return([Monograph]) }

    it 'searches for valid work types' do
      expect(builder.filter_models(solr_params))
        .to contain_exactly("{!terms f=has_model_ssim}Monograph,#{Hyrax.config.collection_class}")
    end

    it 'does not limit to active only' do
      expect(builder.filter_models(solr_params)).not_to include('-suppressed_bsi:true')
    end
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :in_admin_set }
    it { is_expected.not_to include :only_active_works }
  end
end
