require 'spec_helper'

describe VisibilityCopyWorker do
  describe 'an open access work' do
    let(:work) { FactoryGirl.create(:work_with_files) }
    subject { described_class.new(work.id) }

    it 'has no content at the outset' do
      expect(work.generic_files.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it 'copies visibility to its contained files' do
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.save
      subject.run
      work.reload.generic_files.each do |file|
        expect(file.visibility).to eq 'open'
      end
    end
  end

  describe 'an embargoed work' do
    let(:work) { FactoryGirl.create(:embargoed_work_with_files) }
    subject { described_class.new(work.id) }

    before do
      expect(work.visibility).to eq 'restricted'
      expect(work).to be_under_embargo
      expect(work.generic_files.first).to_not be_under_embargo
    end

    context 'when run' do
      before do
        subject.run
        work.reload
      end
      let(:file) { work.generic_files.first }

      it 'copies visibility to its contained files and apply a copy of the embargo to the files' do
        expect(file).to be_under_embargo
        expect(file.embargo.id).to_not eq work.embargo.id
      end
    end
  end

  describe 'an leased work' do
    let(:work) { FactoryGirl.create(:leased_work_with_files) }
    subject { described_class.new(work.id) }

    before do
      expect(work.visibility).to eq 'open'
      expect(work).to be_active_lease
      expect(work.generic_files.first).to_not be_active_lease
    end

    context 'when run' do
      before do
        subject.run
        work.reload
      end
      let(:file) { work.generic_files.first }

      it 'copies visibility to its contained files and apply a copy of the lease to the files' do
        expect(file).to be_active_lease
        expect(file.lease.id).to_not eq work.lease.id
      end
    end
  end
end
