# frozen_string_literal: true
RSpec.describe LeaseExpiryJob, :clean_repo do
  subject { described_class }

  context 'with Valkyrie resources' do
    let!(:leased_work) { valkyrie_create(:hyrax_work, :under_lease) }
    let!(:work_with_expired_lease) { valkyrie_create(:hyrax_work, :with_expired_enforced_lease) }
    let!(:file_set_with_expired_lease) { valkyrie_create(:hyrax_file_set, :with_expired_enforced_lease) }

    describe '#records_with_expired_leases' do
      it 'returns all records with expired leases' do
        record_ids = described_class.new.records_with_expired_leases.map(&:id)
        expect(record_ids.count).to eq(2)
        expect(record_ids).to include(work_with_expired_lease.id)
        expect(record_ids).to include(file_set_with_expired_lease.id)
      end
    end

    describe '#perform' do
      it 'expires leases on works with expired leases' do
        expect(work_with_expired_lease.visibility).to eq('open')
        described_class.new.perform
        reloaded = Hyrax.query_service.find_by(id: work_with_expired_lease.id)
        expect(reloaded.visibility).to eq('authenticated')
      end

      it 'expires leases on filesets with expired leases' do
        expect(file_set_with_expired_lease.visibility).to eq('open')
        described_class.new.perform
        reloaded = Hyrax.query_service.find_by(id: file_set_with_expired_lease.id)
        expect(reloaded.visibility).to eq('authenticated')
      end

      it 'does not expire leases that are still in effect' do
        expect(leased_work.visibility).to eq('open')
        described_class.new.perform
        reloaded = Hyrax.query_service.find_by(id: leased_work.id)
        expect(reloaded.visibility).to eq('open')
      end
    end
  end

  context 'with ActiveFedora objects', :active_fedora do
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
        expect(records.map(&:id))
          .to contain_exactly(work_with_expired_lease.id,
                              file_set_with_expired_lease.id)
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
end
