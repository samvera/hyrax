# frozen_string_literal: true
RSpec.describe EmbargoExpiryJob, :clean_repo do
  subject { described_class }

  context "with Valkyrie resources" do
    let(:embargoed_work) { valkyrie_create(:hyrax_work, :under_embargo) }
    let(:work_with_expired_embargo) { valkyrie_create(:hyrax_work, :with_expired_enforced_embargo) }
    let(:file_set_with_expired_embargo) { valkyrie_create(:hyrax_file_set, :with_expired_enforced_embargo) }

    describe '#records_with_expired_embargos' do
      it 'returns all records with expired embargos' do
        records = [work_with_expired_embargo.id.to_s, file_set_with_expired_embargo.id.to_s]
        expect(described_class.new.records_with_expired_embargos.map { |r| r.id.to_s }).to match_array(records)
      end
    end

    describe '#perform' do
      it 'expires embargos on works with expired embargos' do
        expect(work_with_expired_embargo.visibility).to eq('authenticated')
        described_class.new.perform
        reloaded = Hyrax.query_service.find_by(id: work_with_expired_embargo.id)
        expect(reloaded.visibility).to eq('open')
      end

      it 'expires embargos on file sets with expired embargos' do
        expect(file_set_with_expired_embargo.visibility).to eq('authenticated')
        described_class.new.perform
        reloaded = Hyrax.query_service.find_by(id: file_set_with_expired_embargo.id)
        expect(reloaded.visibility).to eq('open')
      end

      it "Doesn't expire embargos that are still in effect" do
        expect(embargoed_work.visibility).to eq('authenticated')
        described_class.new.perform
        reloaded = Hyrax.query_service.find_by(id: embargoed_work.id)
        expect(reloaded.visibility).to eq('authenticated')
      end
    end
  end

  context 'with ActiveFedora objects', :active_fedora do
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
        work_with_expired_embargo.reload
        expect(work_with_expired_embargo.visibility).to eq('open')
      end

      it 'expires embargos on file sets with expired embargos' do
        described_class.new.perform
        file_set_with_expired_embargo.reload
        expect(file_set_with_expired_embargo.visibility).to eq('open')
      end

      it "Doesn't expire embargos that are still in effect" do
        described_class.new.perform
        embargoed_work.reload
        expect(embargoed_work.visibility).to eq('restricted')
      end
    end
  end
end
