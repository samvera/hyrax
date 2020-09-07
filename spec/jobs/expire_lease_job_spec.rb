# frozen_string_literal: true
RSpec.describe ExpireLeaseJob do
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

  describe '#perform' do
    it 'expires leases on assets with expired leases' do
      described_class.new.perform(work_with_expired_lease)
      described_class.new.perform(leased_work)
      described_class.new.perform(file_set_with_expired_lease)
      leased_work.reload
      file_set_with_expired_lease.reload
      work_with_expired_lease.reload
      expect(work_with_expired_lease.visibility).to eq('restricted')
      expect(file_set_with_expired_lease.visibility).to eq('restricted')
      expect(leased_work.visibility).to eq('open')
    end
  end
end
