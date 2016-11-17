require 'spec_helper'

describe CurationConcerns::Operation do
  describe "rollup_status" do
    let(:parent) { create(:operation, :pending) }
    describe "with a pending process" do
      let!(:child1) { create(:operation, :failing, parent: parent) }
      let!(:child2) { create(:operation, :pending, parent: parent) }
      it "sets status to pending" do
        parent.rollup_status
        expect(parent.status).to eq CurationConcerns::Operation::PENDING
      end
    end

    describe "with a failure" do
      let!(:child1) { create(:operation, :failing, parent: parent) }
      let!(:child2) { create(:operation, :successful, parent: parent) }
      it "sets status to failure" do
        parent.rollup_status
        expect(parent.status).to eq CurationConcerns::Operation::FAILURE
      end
    end

    describe "with a successes" do
      let!(:child1) { create(:operation, :successful, parent: parent) }
      let!(:child2) { create(:operation, :successful, parent: parent) }
      it "sets status to success" do
        parent.rollup_status
        expect(parent.status).to eq CurationConcerns::Operation::SUCCESS
      end
    end
  end

  describe "performing!" do
    it "changes the status to performing" do
      subject.performing!
      expect(subject.status).to eq CurationConcerns::Operation::PERFORMING
    end
  end
end
