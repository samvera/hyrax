require 'spec_helper'

describe VisibilityCopyWorker do

  describe "an open access work" do
    let(:work) { FactoryGirl.create(:work_with_files) }
    subject { VisibilityCopyWorker.new(work.id) }

    it "should have no content at the outset" do
      expect(work.generic_files.first.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it "should copy visibility to its contained files" do
      work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      work.save
      subject.run
      work.reload.generic_files.each do |file|
        expect(file.visibility).to eq 'open'
      end
    end
  end

  describe "an embargoed work" do
    let(:work) { FactoryGirl.create(:embargoed_work_with_files) }
    subject { VisibilityCopyWorker.new(work.id) }

    before do
      expect(work.visibility).to eq 'restricted'
      expect(work).to be_under_embargo
      expect(work.generic_files.first).to_not be_under_embargo
    end

    context "when run" do
      before do
        subject.run
        work.reload
      end
      let(:file) { work.generic_files.first }

      it "should copy visibility to its contained files" do
        expect(file).to be_under_embargo
      end
    end
  end

  describe "an leased work" do
    let(:work) { FactoryGirl.create(:leased_work_with_files) }
    subject { VisibilityCopyWorker.new(work.id) }

    before do
      expect(work.visibility).to eq 'open'
      expect(work).to be_active_lease
      expect(work.generic_files.first).to_not be_active_lease
    end

    context "when run" do
      before do
        subject.run
        work.reload
      end
      let(:file) { work.generic_files.first }

      it "should copy visibility to its contained files" do
        expect(file).to be_active_lease
      end
    end
  end
end
