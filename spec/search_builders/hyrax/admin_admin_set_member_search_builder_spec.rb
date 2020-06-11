# frozen_string_literal: true
RSpec.describe Hyrax::AdminAdminSetMemberSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:user_groups) { [] }
  let(:ability) do
    instance_double(Ability,
                    admin?: true,
                    user_groups: user_groups,
                    current_user: user)
  end
  let(:user) { create(:user) }
  let(:admin_set) { double(id: '123') }
  let(:builder) { described_class.new(scope: context, collection: admin_set) }

  describe '#filter_models' do
    before do
      # This prevents any generated classes from interfering with this test:
      allow(builder).to receive(:work_classes).and_return([GenericWork])
      builder.filter_models(solr_params)
    end
    let(:solr_params) { { fq: [] } }

    it 'searches for valid work types' do
      expect(solr_params[:fq].first).to include('{!terms f=has_model_ssim}GenericWork,Collection')
    end
    it 'does not limit to active only' do
      expect(solr_params[:fq].first).not_to include('-suppressed_bsi:true')
    end
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :in_admin_set }
    it { is_expected.not_to include :only_active_works }
  end
end
