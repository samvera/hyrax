# frozen_string_literal: true
RSpec.describe Hyrax::EmbargoService, :clean_repo do
  subject(:service) { described_class }

  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  let!(:work_with_expired_enforced_embargo1) do
    FactoryBot.valkyrie_create(:hyrax_work, :with_expired_enforced_embargo)
  end

  let!(:work_with_expired_enforced_embargo2) do
    FactoryBot.valkyrie_create(:hyrax_work, :with_expired_enforced_embargo)
  end

  let!(:work_with_released_embargo) do
    FactoryBot.create(:embargoed_work, with_embargo_attributes: { embargo_date: past_date.to_s })
  end

  let!(:work_with_embargo_in_effect) do
    FactoryBot.create(:embargoed_work, with_embargo_attributes: { embargo_date: future_date.to_s })
  end

  let!(:work_without_embargo) { create(:generic_work) }

  describe '#assets_with_expired_embargoes' do
    it 'returns an array of assets with expired embargoes that are still enforced' do
      expect(service.assets_with_expired_embargoes)
        .to contain_exactly(have_attributes(id: work_with_expired_enforced_embargo1.id),
                            have_attributes(id: work_with_expired_enforced_embargo2.id))
    end
  end

  describe '#assets_with_enforced_embargoes' do
    it 'returns all assets with enforced embargoes' do
      expect(service.assets_under_embargo)
        .to contain_exactly(have_attributes(id: work_with_embargo_in_effect.id),
                            have_attributes(id: work_with_expired_enforced_embargo1.id),
                            have_attributes(id: work_with_expired_enforced_embargo2.id))
    end

    context 'after the embargo is released' do
      before do
        Hyrax::EmbargoManager.release_embargo_for(resource: work_with_expired_enforced_embargo1)
        work_with_expired_enforced_embargo1.permission_manager.acl.save
      end

      it 'does not include the work' do
      expect(service.assets_under_embargo)
        .to contain_exactly(have_attributes(id: work_with_embargo_in_effect.id),
                            have_attributes(id: work_with_expired_enforced_embargo2.id))
      end
    end
  end

  describe '#assets_with_deactivated_embargoes' do
    let(:id) { Noid::Rails::Service.new.mint }
    let(:attributes) do
      { 'embargo_history_ssim' => ['This is in the past'],
        'id' => id }
    end

    before do
      Hyrax::SolrService.add(attributes)
      Hyrax::SolrService.commit
    end

    it 'returns all assets with embargo history set' do
      expect(service.assets_with_deactivated_embargoes)
        .to contain_exactly(have_attributes(id: id),
                            have_attributes(id: work_with_released_embargo.id))
    end
  end
end
