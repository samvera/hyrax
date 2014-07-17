require 'spec_helper'

describe Sufia::IdService do
  describe "mint" do
    subject { Sufia::IdService.mint }

    it { should_not be_empty }

    it "should not mint the same id twice in a row" do
      expect(Sufia::IdService.mint).to_not eq subject
    end

    it "should be valid" do    
      expect(Sufia::IdService.valid?(subject)).to be true
    end

    context "when the pid already exists in Fedora" do
      let(:mock_pid) { 'scholarsphere:ef12ef12f' }
      let(:unique_pid) {  'scholarsphere:bb22bb22b' }

      before do
        allow(Sufia::IdService).to receive(:next_id).and_return(mock_pid, unique_pid)
        expect(ActiveFedora::Base).to receive(:exists?).with(mock_pid).and_return(true)
        expect(ActiveFedora::Base).to receive(:exists?).with(unique_pid).and_return(false)
      end

      it "should not assign that pid again" do
        expect(subject).to eq unique_pid
      end
    end
  end


end
