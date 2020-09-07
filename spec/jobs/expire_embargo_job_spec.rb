RSpec.describe ExpireEmbargoJob do
  subject { described_class }

  let(:work) { create(:embargoed_work) }
  let(:past_date) { 2.days.ago }

  let!(:embargoed_file_set) do
    build(:file_set, embargo_release_date: past_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#perform' do
    it 'expires embargos on assets with expired embargos' do
      described_class.new.perform
      work.reload
      embargoed_file_set.reload
      expect(work.visibility).to eq(work.future_state)
      expect(file_set.visibility).to eq(embargoed_file_set.visibility_after_embargo)
    end
  end

end
