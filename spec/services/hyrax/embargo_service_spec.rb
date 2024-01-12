# frozen_string_literal: true
RSpec.describe Hyrax::EmbargoService, :clean_repo do
  subject(:service) { described_class }
  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }
  let!(:work_with_expired_enforced_embargo1) { valkyrie_create(:hyrax_work, :with_expired_enforced_embargo) }
  let!(:work_with_expired_enforced_embargo2) { valkyrie_create(:hyrax_work, :with_expired_enforced_embargo) }

  shared_context('with a fake Solr hash with embargo_history_ssim populated') do
    let(:id) { Noid::Rails::Service.new.mint }
    let(:attributes) do
      { 'embargo_history_ssim' => ['This is in the past'],
        'id' => id }
    end

    before do
      Hyrax::SolrService.add(attributes)
      Hyrax::SolrService.commit
    end
  end

  shared_examples('tests #assets_with_expired_embargoes') do
    describe '#assets_with_expired_embargoes' do
      it 'returns an array of assets with expired embargoes that are still enforced' do
        expect(service.assets_with_expired_embargoes)
          .to contain_exactly(have_attributes(id: work_with_expired_enforced_embargo1.id),
                              have_attributes(id: work_with_expired_enforced_embargo2.id))
      end
    end
  end

  shared_examples('tests #assets_with_enforced_embargoes') do
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
  end

  shared_examples('tests that #assets_with_deactivated_embargoes returns all with embargo_history_ssim') do
    it 'returns all assets with embargo history set' do
      expect(service.assets_with_deactivated_embargoes)
        .to contain_exactly(have_attributes(id: id),
                            have_attributes(id: work_with_released_embargo.id))
    end
  end

  if Hyrax.config.disable_wings
    let!(:work_with_released_embargo) { valkyrie_create(:hyrax_work, embargo: released_embargo) }
    let(:released_embargo) { valkyrie_create(:hyrax_embargo, embargo_release_date: past_date) }
    let!(:work_with_embargo_in_effect) { valkyrie_create(:hyrax_work, embargo: embargo_in_effect) }
    let(:embargo_in_effect) { valkyrie_create(:hyrax_embargo, embargo_release_date: future_date) }
    let!(:work_without_embargo) { valkyrie_create(:hyrax_work) }

    include_examples 'tests #assets_with_expired_embargoes'
    include_examples 'tests #assets_with_enforced_embargoes'

    describe '#assets_with_deactivated_embargoes' do
      include_context 'with a fake Solr hash with embargo_history_ssim populated'

      before do
        Hyrax::EmbargoManager.deactivate_embargo_for!(resource: work_with_released_embargo)
        work_with_released_embargo.permission_manager.acl.save
      end

      include_examples 'tests that #assets_with_deactivated_embargoes returns all with embargo_history_ssim'
    end
  else
    # NOTE: This test suite is the original Dassie sequence. Notice the combination of Valkyrie and ActiveFedora objects.
    #   An attempt was made to use only Valkyrie objects across both Dassie and Koppie, but each environment returns different results.
    #   This is very similar to the test suite at spec/services/hyrax/lease_service_spec.rb.
    let!(:work_with_released_embargo) { create(:embargoed_work, with_embargo_attributes: { embargo_date: past_date.to_s }) }
    let!(:work_with_embargo_in_effect) { create(:embargoed_work, with_embargo_attributes: { embargo_date: future_date.to_s }) }
    let!(:work_without_embargo) { create(:generic_work) }

    include_examples 'tests #assets_with_expired_embargoes'
    include_examples 'tests #assets_with_enforced_embargoes'

    describe '#assets_with_deactivated_embargoes' do
      include_context 'with a fake Solr hash with embargo_history_ssim populated'

      include_examples 'tests that #assets_with_deactivated_embargoes returns all with embargo_history_ssim'
    end
  end
end
