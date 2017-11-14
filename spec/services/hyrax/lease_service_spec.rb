RSpec.describe Hyrax::LeaseService do
  subject { described_class }

  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  let!(:work_with_expired_lease1) { create_for_repository(:work, lease_expiration_date: past_date.to_s) }
  let!(:work_with_expired_lease2) { create_for_repository(:work, lease_expiration_date: past_date.to_s) }
  let!(:work_with_lease_in_effect) { create_for_repository(:work, lease_expiration_date: future_date.to_s) }
  let!(:work_without_lease) { create_for_repository(:work) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }

  describe '#assets_with_expired_leases' do
    it 'returns an array of assets with expired lease' do
      returned_pids = subject.assets_with_expired_leases.map(&:id)
      expect(returned_pids).to include work_with_expired_lease1.id, work_with_expired_lease2.id
      expect(returned_pids).not_to include work_with_lease_in_effect.id, work_without_lease.id
    end
  end

  describe '#assets_under_lease' do
    it 'returns an array of assets with active leases' do
      returned_pids = subject.assets_under_lease.map(&:id)
      expect(returned_pids).to include work_with_expired_lease1.id, work_with_expired_lease2.id, work_with_lease_in_effect.id
      expect(returned_pids).not_to include work_without_lease.id
    end
  end

  describe '#assets_with_deactivated_leases' do
    before do
      work_with_expired_lease1.deactivate_lease!
      persister.save(resource: work_with_expired_lease1)
      work_with_lease_in_effect.deactivate_lease!
      persister.save(resource: work_with_lease_in_effect)
    end
    it 'returns an array of assets with deactivated leases' do
      returned_pids = subject.assets_with_deactivated_leases.map(&:id)
      expect(returned_pids).to include work_with_expired_lease1.id, work_with_lease_in_effect.id
    end
  end
end
