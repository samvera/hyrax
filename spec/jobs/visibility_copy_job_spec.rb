# frozen_string_literal: true

RSpec.describe VisibilityCopyJob do
  context 'context with a valkyrie resource' do
    let(:work)    { FactoryBot.create(:work_with_files).valkyrie_resource }
    let(:queries) { Hyrax.query_service.custom_queries }

    it 'copies visibility to file sets' do
      work.visibility = 'open'

      expect { described_class.perform_now(work) }
        .to change { queries.find_child_filesets(resource: work).map(&:visibility) }
        .to ['open', 'open']
    end

    context 'with an embargo' do
      let(:work) { FactoryBot.create(:embargoed_work_with_files).valkyrie_resource }

      it 'applies a copy of the embargo' do
        release_date = work.embargo.embargo_release_date

        expect { described_class.perform_now(work) }
          .to change { queries.find_child_filesets(resource: work).map(&:embargo) }
          .to contain_exactly(have_attributes(embargo_release_date: release_date),
                              have_attributes(embargo_release_date: release_date))
      end
    end

    context 'when work is under lease' do
      let(:work) { FactoryBot.create(:leased_work_with_files).valkyrie_resource }

      it 'applies a copy of the embargo' do
        release_date = work.lease.lease_expiration_date

        expect { described_class.perform_now(work) }
          .to change { queries.find_child_filesets(resource: work).map(&:lease) }
          .to contain_exactly(have_attributes(lease_expiration_date: release_date),
                              have_attributes(lease_expiration_date: release_date))
      end
    end
  end

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
