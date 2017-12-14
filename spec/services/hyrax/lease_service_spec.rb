RSpec.describe Hyrax::LeaseService, :clean_repo do
  let(:service) { described_class }

  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  let(:expired_lease) do
    create_for_repository(:lease, lease_expiration_date: [past_date])
  end
  let(:current_lease) do
    create_for_repository(:lease, lease_expiration_date: [future_date])
  end
  let!(:work_with_expired_lease1) do
    create_for_repository(:work, lease_id: expired_lease.id)
  end
  let!(:work_with_expired_lease2) do
    create_for_repository(:work, lease_id: expired_lease.id)
  end
  let!(:work_with_lease_in_effect) do
    create_for_repository(:work, lease_id: current_lease.id)
  end
  let!(:work_without_lease) { create_for_repository(:work) }

  describe '#assets_with_expired_leases' do
    subject { service.assets_with_expired_leases.map(&:id) }

    it 'returns an array of assets with expired lease' do
      expect(subject).to contain_exactly(
        work_with_expired_lease1.id.to_s,
        work_with_expired_lease2.id.to_s
      )
    end
  end

  describe '#assets_under_lease' do
    subject { service.assets_under_lease.map(&:id) }

    it 'returns an array of assets with active leases' do
      expect(subject).to contain_exactly(
        work_with_expired_lease1.id.to_s,
        work_with_expired_lease2.id.to_s,
        work_with_lease_in_effect.id.to_s
      )
    end
  end

  describe '#assets_with_deactivated_leases' do
    subject { service.assets_with_deactivated_leases.map(&:id) }

    let(:expired_lease) { create_for_repository(:lease, lease_history: ['this is inactive']) }
    let(:current_lease) { create_for_repository(:lease, lease_history: ['also inactive']) }

    it 'returns an array of assets with deactivated leases' do
      expect(subject).to include work_with_expired_lease1.id.to_s, work_with_lease_in_effect.id.to_s
    end
  end
end
