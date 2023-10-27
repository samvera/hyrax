# frozen_string_literal: true

RSpec.describe Hyrax::FileSetVisibilityPropagator, :active_fedora do
  subject(:propagator) { described_class.new(source: work) }
  let(:work)           { FactoryBot.create(:work_with_files) }

  context 'a public work' do
    before do
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    it 'copies visibility to its contained files' do
      # files are private at the outset
      expect(work.file_sets.first.visibility)
        .to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

      propagator.propagate

      work.reload.file_sets.each do |file|
        expect(file.visibility)
          .to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
  end

  context 'when work is under embargo' do
    let(:work) { create(:embargoed_work_with_files) }
    let(:file) { work.file_sets.first }

    it 'copies visibility to its contained files and apply a copy of the embargo to the files' do
      expect(work.visibility)
        .to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      expect(work).to be_under_embargo
      expect(work.file_sets.first).not_to be_under_embargo

      propagator.propagate

      expect(file).to be_under_embargo
      expect(file.embargo.id).not_to eq work.embargo.id
    end
  end

  context 'when work is under lease' do
    let(:work) { create(:leased_work_with_files) }
    let(:file) { work.file_sets.first }

    it 'copies visibility to its contained files and apply a copy of the lease to the files' do
      expect(work.visibility)
        .to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(work).to be_active_lease
      expect(work.file_sets.first).not_to be_active_lease

      propagator.propagate

      expect(file).to be_active_lease
      expect(file.lease.id).not_to eq work.lease.id
    end
  end
end
