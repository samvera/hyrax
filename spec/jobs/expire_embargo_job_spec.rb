# frozen_string_literal: true
RSpec.describe ExpireEmbargoJob do
  subject { described_class }

  let(:past_date) { 2.days.ago }

  let(:embargoed_work) { create(:embargoed_work) }

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

  describe '#perform' do
    it 'expires embargos on assets with expired embargos' do
      described_class.new.perform(work_with_expired_embargo)
      described_class.new.perform(embargoed_work)
      described_class.new.perform(file_set_with_expired_embargo)
      embargoed_work.reload
      file_set_with_expired_embargo.reload
      work_with_expired_embargo.reload
      expect(work_with_expired_embargo.visibility).to eq('open')
      expect(file_set_with_expired_embargo.visibility).to eq('open')
      expect(embargoed_work.visibility).to eq('restricted')
    end
  end
end
