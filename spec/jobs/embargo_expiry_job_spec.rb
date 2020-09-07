# frozen_string_literal: true
RSpec.describe EmbargoExpiryJob do
  subject { described_class }

  let(:past_date) { 2.days.ago }

  let(:embargoed_work) { create(:embargoed_work) }

  let!(:work_with_expired_embargo) do
    build(:work, embargo_release_date: past_date.to_s).tap do |work|
      work.save(validate: false)
    end
  end

  let!(:file_set_with_expired_embargo) do
    build(:file_set, embargo_release_date: past_date.to_s).tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#records_with_expired_embargos' do
    it 'returns all records with expired embargos' do
      records = described_class.new.records_with_expired_embargos
      expect(records).to include work_with_expired_embargo, file_set_with_expired_embargo
      expect(records).not_to include embargoed_work
    end
  end

  describe '#perform' do
    it "Enqueues an Expire Embargo job for each expired record" do
      expect { described_class.perform_now }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(described_class.new.records_with_expired_embargos.count)
    end
  end
end
