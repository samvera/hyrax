Rspec.describe EmbargoExpiryJob do

  let(:work) { create(:embargoed_work) }
  let(:past_date) { 2.days.ago }

  let!(:embargoed_file_set) do
    build(:file_set, embargo_release_date: past_date.to_s, visibility_during_embargo: 'restricted', visibility_after_embargo: 'open').tap do |file_set|
      file_set.save(validate: false)
    end
  end

  describe '#get_records_with_expired_embargos' do
    it 'returns an Array of works with expired embargos' do
      works = described_class.new.get_records_with_expired_embargos
      expect(works).to include work
    end

    it 'returns an array of expired file sets' do
      records = described_class.new.get_records_with_expired_embargos
      expect(records).to include embargoed_file_set
    end
  end


  describe '#perform' do
    it "Expires all embargos automatically" do
      described_class.new.perform
      work.reload
      embargoed_file_set.reload
      expect(work.visibility).to eq "open"
      expect(embargoed_file_set.visibility).to eq "open"
    end
  end
end
