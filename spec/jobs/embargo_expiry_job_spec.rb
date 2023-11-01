# frozen_string_literal: true
RSpec.describe EmbargoExpiryJob, :clean_repo do
  subject { described_class }
  let(:past_date) { 2.days.ago }
  let(:embargoed_work) { valkyrie_create(:hyrax_work, embargo: work_set_embargo) }
  let(:work_set_embargo) { valkyrie_create(:hyrax_embargo, visibility_during_embargo: 'restricted') }

  let(:work_with_expired_embargo) { valkyrie_create(:hyrax_work, embargo: work_set_embargo_expired) }
  let(:work_set_embargo_expired) { valkyrie_create(:hyrax_embargo, embargo_release_date: past_date, visibility_during_embargo: 'restricted') }

  let(:file_set_with_expired_embargo) { valkyrie_create(:hyrax_file_set, embargo: file_set_embargo) }
  let(:file_set_embargo) { valkyrie_create(:hyrax_embargo, embargo_release_date: past_date, visibility_during_embargo: 'restricted') }

  describe '#records_with_expired_embargos' do
    it 'returns all records with expired embargos' do
      records = described_class.new.records_with_expired_embargos

      expect(records.map(&:id))
        .to contain_exactly(work_with_expired_embargo.id,
                            file_set_with_expired_embargo.id)
    end
  end

  describe '#perform' do
    it 'expires embargos on works with expired embargos' do
      described_class.new.perform
      # work_with_expired_embargo.reload
      expect(work_with_expired_embargo.visibility).to eq('open')
    end

    it 'expires embargos on file sets with expired embargos' do
      described_class.new.perform
      # file_set_with_expired_embargo.reload
      expect(file_set_with_expired_embargo.visibility).to eq('open')
    end

    it "Doesn't expire embargos that are still in effect" do
      described_class.new.perform
      # embargoed_work.reload
      expect(embargoed_work.visibility).to eq('restricted')
    end
  end
end
