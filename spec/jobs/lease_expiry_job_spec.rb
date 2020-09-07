# frozen_string_literal: true
RSpec.describe LeaseExpiryJob do
  subject { described_class }

  let(:past_date) { 2.days.ago }

  let(:leased_work) { create(:leased_work) }

  let!(:work_with_expired_lease) do
    build(:work, lease_expiration_date: past_date.to_s).tap do |work|
      work.save(validate: false)
    end
  end

  let!(:file_set_with_expired_lease) do
    build(:file_set, lease_expiration_date: past_date.to_s).tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#records_with_expired_leases' do
    it 'returns all records with expired leases' do
      records = described_class.new.records_with_expired_leases
      expect(records).to include work_with_expired_lease, file_set_with_expired_lease
      expect(records).not_to include leased_work
    end
  end

  describe '#perform' do
    it "Enqueues an Expire Lease job for each expired record" do
      expect { described_class.perform_now }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(described_class.new.records_with_expired_leases.count)
    end
  end
end
