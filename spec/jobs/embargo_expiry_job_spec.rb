# frozen_string_literal: true
RSpec.describe EmbargoExpiryJob do
  subject { described_class }

  let(:past_date) { 2.days.ago }

  let(:work) { create(:embargoed_work) }

  let!(:work_with_expired_embargo) do
    build(:work, embargo_release_date: past_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |work|
      work.save(validate: false)
    end
  end

  let!(:file_set_with_expired_embargo) do
    build(:file_set, embargo_release_date: past_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#records_with_expired_embargos' do
    it 'returns all records with expired embargos' do
      records = described_class.new.records_with_expired_embargos
      expect(records).to include work_with_expired_embargo
      expect(records).to include embargoed_file_set
    end
  end

  describe '#perform' do
    it "Enqueues an Expire Embargo job " do
      expect { described_class.perform }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      expect { described_class.perform }.to have_enqueued_job(ExpireEmbargoJob)
    end
  end
end
