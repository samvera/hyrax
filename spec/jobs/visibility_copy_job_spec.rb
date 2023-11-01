# frozen_string_literal: true

RSpec.describe VisibilityCopyJob do
  context 'with a valkyrie resource' do
    let(:proxy)    { Hyrax::ActiveJobProxy.new(resource: resource) }
    let(:resource) { valkyrie_create(:hyrax_work, :with_member_file_sets, visibility_setting: 'open') }
    let(:queries)  { Hyrax.custom_queries }

    it 'serializes and deserializes resource transparently' do
      expect { described_class.perform_later(resource) }
        .to have_enqueued_job
        .with(resource)
    end

    it 'copies visibility to file sets' do
      expect { described_class.perform_now(resource) }
        .to change { queries.find_child_file_sets(resource: resource).map(&:visibility) }
        .from(['restricted', 'restricted']).to(['open', 'open'])
    end

    context 'with an embargo' do
      let(:resource) { valkyrie_create(:hyrax_work, :with_member_file_sets, :under_embargo) }

      it 'applies a copy of the embargo' do
        release_date = resource.embargo.embargo_release_date

        expect { described_class.perform_now(resource) }
          .to change { queries.find_child_file_sets(resource: resource).map(&:embargo) }
          .to contain_exactly(have_attributes(embargo_release_date: release_date),
                              have_attributes(embargo_release_date: release_date))
      end
    end

    context 'when work is under lease' do
      let(:resource) { valkyrie_create(:hyrax_work, :with_member_file_sets, :under_lease) }

      it 'applies a copy of the embargo' do
        release_date = resource.lease.lease_expiration_date

        expect { described_class.perform_now(resource) }
          .to change { queries.find_child_file_sets(resource: resource).map(&:lease) }
          .to contain_exactly(have_attributes(lease_expiration_date: release_date),
                              have_attributes(lease_expiration_date: release_date))
      end
    end
  end

  context 'with ActiveFedora work', :active_fedora do
    describe 'an open access work' do
      let(:work) { create(:work_with_files) }

      it 'copies visibility to its contained files' do
        # files are private at the outset
        expect(work.file_sets.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

        work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        work.save
        described_class.perform_now(work)
        work.reload.file_sets.each do |file|
          expect(file.visibility).to eq 'open'
        end
      end
    end

    describe 'an embargoed work' do
      let(:work) { create(:embargoed_work_with_files) }
      let(:file) { work.file_sets.first }

      before do
        expect(work.visibility).to eq 'restricted'
        expect(work).to be_under_embargo
        expect(work.file_sets.first).not_to be_under_embargo
        described_class.perform_now(work)
        work.reload
      end

      it 'copies visibility to its contained files and apply a copy of the embargo to the files' do
        expect(file).to be_under_embargo
        expect(file.embargo.id).not_to eq work.embargo.id
      end
    end

    describe 'an leased work' do
      let(:work) { create(:leased_work_with_files) }
      let(:file) { work.file_sets.first }

      before do
        expect(work.visibility).to eq 'open'
        expect(work).to be_active_lease
        expect(work.file_sets.first).not_to be_active_lease
        described_class.perform_now(work)
        work.reload
      end

      it 'copies visibility to its contained files and apply a copy of the lease to the files' do
        expect(file).to be_active_lease
        expect(file.lease.id).not_to eq work.lease.id
      end
    end
  end
end
