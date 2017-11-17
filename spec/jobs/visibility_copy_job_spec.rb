RSpec.describe VisibilityCopyJob do
  describe 'an open access work' do
    let(:work) { create_for_repository(:work_with_files, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }
    let(:reloaded) { Hyrax::Queries.find_by(id: work.id) }

    it 'copies visibility to its contained files' do
      # files are private at the outset
      expect(work.file_sets.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

      described_class.perform_now(work.id)
      reloaded.file_sets.each do |file|
        expect(file.visibility).to eq 'open'
      end
    end
  end

  describe 'an embargoed work' do
    let(:work) { create_for_repository(:embargoed_work_with_files) }
    let(:file) { work.file_sets.first }
    let(:reloaded) { Hyrax::Queries.find_by(id: file.id) }

    before do
      expect(work.visibility).to eq 'restricted'
      expect(work.embargo_id).to be_present
      expect(work.file_sets.first.embargo_id).not_to be_present
      described_class.perform_now(work.id)
    end

    it 'copies visibility to its contained files and apply a copy of the embargo to the files' do
      expect(reloaded.embargo_id).to be_present
      expect(reloaded.embargo_id).not_to eq work.embargo_id
    end
  end

  describe 'an leased work' do
    let(:work) { create_for_repository(:leased_work_with_files) }
    let(:file) { work.file_sets.first }
    let(:reloaded) { Hyrax::Queries.find_by(id: file.id) }

    before do
      expect(work.visibility).to eq 'open'
      expect(work.lease_id).to be_present
      expect(work.file_sets.first.lease_id).not_to be_present
      described_class.perform_now(work.id)
    end

    it 'copies visibility to its contained files and apply a copy of the lease to the files' do
      expect(reloaded.lease_id).to be_present
      expect(reloaded.lease_id).not_to eq work.lease_id
    end
  end
end
