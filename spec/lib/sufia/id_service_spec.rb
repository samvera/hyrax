require 'spec_helper'

describe Sufia::IdService do
  describe "mint" do
    subject { Sufia::IdService.mint }

    it { is_expected.not_to be_empty }

    it "should not mint the same id twice in a row" do
      expect(Sufia::IdService.mint).to_not eq subject
    end

    it "should be valid" do
      expect(Sufia::IdService.valid?(subject)).to be true
    end

    context "when the id already exists in Fedora" do
      let(:mock_id) { 'ef12ef12f' }
      let(:unique_id) { 'bb22bb22b' }

      before do
        allow(Sufia::IdService).to receive(:next_id).and_return(mock_id, unique_id)
        expect(ActiveFedora::Base).to receive(:exists?).with(mock_id).and_return(true)
        expect(ActiveFedora::Base).to receive(:exists?).with(unique_id).and_return(false)
      end

      it "should not assign that id again" do
        expect(subject).to eq unique_id
      end
    end
  end
end
