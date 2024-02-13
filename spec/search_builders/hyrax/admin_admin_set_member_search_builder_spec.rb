# frozen_string_literal: true
RSpec.describe Hyrax::AdminAdminSetMemberSearchBuilder do
  subject(:builder) { described_class.new(scope: scope, collection: admin_set) }
  let(:ability) { Ability.new(user) }
  let(:admin_set) { :FAKE_ADMIN_SET }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: ability) }
  let(:user) { FactoryBot.build(:user) }

  let(:solr_params) { { fq: [] } }

  describe '#filter_models' do
    before { allow(Hyrax::ModelRegistry).to receive(:work_classes).and_return([Monograph]) }

    it 'searches for valid work types' do
      expect(builder.filter_models(solr_params))
        .to contain_exactly(include("{!terms f=has_model_ssim}Monograph"))
    end

    it 'searches for collections indexed as ActiveFedora' do
      expect(builder.filter_models(solr_params))
        .to contain_exactly(include("Collection"))
    end

    it 'searches for collections indexed as valkyrie' do
      expect(builder.filter_models(solr_params))
        .to contain_exactly(include(Hyrax.config.collection_class.to_s))
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
