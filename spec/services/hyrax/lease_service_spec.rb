# frozen_string_literal: true
RSpec.describe Hyrax::LeaseService, :clean_repo do
  subject { described_class }

  let(:expired_lease) { valkyrie_create(:hyrax_lease, :expired) }
  let(:another_expired_lease) { valkyrie_create(:hyrax_lease, :expired) }
  let(:current_lease) { valkyrie_create(:hyrax_lease) }

  let(:work_with_expired_lease1) { valkyrie_create(:monograph, lease: expired_lease) }
  let(:work_with_expired_lease2) { valkyrie_create(:monograph, lease: another_expired_lease) }
  let(:work_with_lease_in_effect) { valkyrie_create(:monograph, lease: current_lease) }
  let(:work_without_lease) { valkyrie_create(:monograph) }

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

  describe '#assets_under_lease' do
    it 'returns an array of assets with active leases' do
      returned_pids = subject.assets_under_lease.map(&:id)
      expect(returned_pids).to include work_with_lease_in_effect.id
      expect(returned_pids).not_to include work_with_expired_lease1.id, work_with_expired_lease2.id, work_without_lease.id
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
      returned_pids = subject.assets_with_deactivated_leases.map(&:id)
      expect(returned_pids).to include work_with_expired_lease1.id, work_with_lease_in_effect.id
    end
  end
end
