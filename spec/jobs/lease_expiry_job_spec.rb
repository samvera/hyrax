# frozen_string_literal: true
RSpec.describe LeaseExpiryJob, :clean_repo do
  subject { described_class }

  let(:past_date) { 2.days.ago }

  let(:leased_work) { create(:leased_work) }

  let!(:work_with_expired_lease) do
    build(:work, lease_expiration_date: past_date.to_s, visibility_during_lease: 'open', visibility_after_lease: 'restricted').tap do |work|
      work.save(validate: false)
    end
  end

  let!(:file_set_with_expired_lease) do
    build(:file_set, lease_expiration_date: past_date.to_s, visibility_during_lease: 'open', visibility_after_lease: 'restricted').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#records_with_expired_leases' do
    it 'returns all records with expired leases' do
      records = described_class.new.records_with_expired_leases
      expect(records).to include work_with_expired_lease.id, file_set_with_expired_lease.id
      expect(records).not_to include leased_work.id
    end
  end

  describe '#perform' do
    it 'expires leases on works with expired leases' do
      described_class.new.perform
      work_with_expired_lease.reload
      expect(work_with_expired_lease.visibility).to eq('restricted')
    end

    it 'expires leases on filesets with expired leases' do
      described_class.new.perform
      file_set_with_expired_lease.reload
      expect(file_set_with_expired_lease.visibility).to eq('restricted')
    end

    it 'does not expire leases that are still in effect' do
      described_class.new.perform
      leased_work.reload
      expect(leased_work.visibility).to eq('open')
    end
  end
end
