# frozen_string_literal: true
RSpec.describe Hyrax::LeaseService, :clean_repo do
  subject { described_class }

  if I18n.t('hyrax.product_name') != 'Koppie'
    let(:future_date) { 2.days.from_now }
    let(:past_date) { 2.days.ago }

    let!(:work_with_expired_lease1) do
      build(:generic_work, lease_expiration_date: past_date.to_s).tap { |work| work.save(validate: false) }
    end
    let!(:work_with_expired_lease2) do
      build(:generic_work, lease_expiration_date: past_date.to_s).tap { |work| work.save(validate: false) }
    end
    let!(:work_with_lease_in_effect) { create(:generic_work, lease_expiration_date: future_date.to_s) }
    let!(:work_without_lease) { create(:generic_work) }

    describe '#assets_with_expired_leases' do
      it 'returns an array of assets with expired lease' do
        process_pid_inclusion_exclusion(:assets_with_expired_leases,
                                        [work_with_expired_lease1.id, work_with_expired_lease2.id],
                                        [work_with_lease_in_effect.id, work_without_lease.id])
      end
    end

    describe '#assets_under_lease' do
      it 'returns an array of assets with active leases' do
        process_pid_inclusion_exclusion(:assets_under_lease,
                                        [work_with_expired_lease1.id, work_with_expired_lease2.id, work_with_lease_in_effect.id],
                                        [work_without_lease.id])
      end
    end

    describe '#assets_with_deactivated_leases' do
      before do
        work_with_expired_lease1.deactivate_lease!
        work_with_expired_lease1.save!
        work_with_lease_in_effect.deactivate_lease!
        work_with_lease_in_effect.save!
      end
      it 'returns an array of assets with deactivated leases' do
        process_pid_inclusion_exclusion(:assets_with_deactivated_leases,
                                        [work_with_expired_lease1.id, work_with_lease_in_effect.id])
      end
    end

  # NOTE: The below Rspec steup only pases in Koppie. See comment below.
  else
    let(:expired_lease) { valkyrie_create(:hyrax_lease, :expired) }
    let(:another_expired_lease) { valkyrie_create(:hyrax_lease, :expired) }
    let(:current_lease) { valkyrie_create(:hyrax_lease) }

    let(:work_with_expired_lease1) { valkyrie_create(:hyrax_work, lease: expired_lease) }
    let(:work_with_expired_lease2) { valkyrie_create(:hyrax_work, lease: another_expired_lease) }
    let(:work_with_lease_in_effect) { valkyrie_create(:hyrax_work, lease: current_lease) }
    let(:work_without_lease) { valkyrie_create(:hyrax_work) }

    let!(:lease_manager) { Hyrax::LeaseManager }

    before do
      work_with_expired_lease1
      work_with_expired_lease2
      work_with_lease_in_effect
      work_without_lease
    end

    # With Valkyrie Work indexing (app/indexers/hyrax/valkyrie_work_indexer.rb:59),
    #   lease_expiration_date_dtsi is only populated when there's an active lease in place.
    #   Since the LeaseService always queries Solr, this will always be an empty array.
    describe '#assets_with_expired_leases' do
      it 'returns an array of assets with expired lease' do
        expect(subject.assets_with_expired_leases).to be_empty
      end
    end

    # Similar to #assets_with_expired_leases, since this is querying Solr objects
    #   that only index lease_expiration_date_dtsi if there's an active lease at time
    #   of processing, this only includes 1 work, not the expected 3.
    describe '#assets_under_lease' do
      it 'returns an array of assets with active leases' do
        process_pid_inclusion_exclusion(:assets_under_lease,
                                      [work_with_lease_in_effect.id],
                                      [work_with_expired_lease1.id, work_with_expired_lease2.id, work_without_lease.id])
      end
    end

    describe '#assets_with_deactivated_leases' do
      before do
        lease_manager.new(resource: work_with_expired_lease1).deactivate!
        Hyrax::AccessControlList(work_with_expired_lease1).save
        lease_manager.new(resource: work_with_lease_in_effect).deactivate!
        Hyrax::AccessControlList(work_with_lease_in_effect).save
      end

      it 'returns an array of assets with deactivated leases' do
        process_pid_inclusion_exclusion(:assets_with_deactivated_leases,
                                      [work_with_expired_lease1.id, work_with_lease_in_effect.id])
      end
    end
  end

  def process_pid_inclusion_exclusion(lease_method = nil, inclusion_arr = nil, exclusion_arr = nil)
    returned_pids = subject.send(lease_method).map(&:id)

    expect(returned_pids).to include(*inclusion_arr) if inclusion_arr.present?
    expect(returned_pids).not_to include(*exclusion_arr) if exclusion_arr.present?
  end
end
