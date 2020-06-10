# frozen_string_literal: true
RSpec.describe Hyrax::Operation do
  describe '#status' do
    it 'is protected by enum enforcement' do
      expect { described_class.new(status: 'not_valid') }.to raise_error(ArgumentError)
    end

    # Because the Rails documentation says "Declare an enum attribute where the values map to integers in the database, but can be queried by name." but appears to not be the case.
    it 'is persisted as a string' do
      create(:operation, :pending)
      values = described_class.connection.execute("SELECT * FROM #{described_class.quoted_table_name}")
      expect(values.first.fetch('status')).to eq(described_class::PENDING)
    end
  end

  describe '#rollup_messages' do
    subject { operation.rollup_messages }

    context 'with no message and no children' do
      let(:operation) { create(:operation, :failing, message: nil) }

      it { is_expected.to eq [] }
    end
    context 'with a message and no children' do
      let(:operation) { create(:operation, :failing, message: 'A bad thing!') }

      it { is_expected.to eq ['A bad thing!'] }
    end
    context 'with a message and children with messages' do
      let(:operation) { create(:operation, :failing, message: 'A bad thing!') }
      let(:child1) { create(:operation, :failing, message: 'Foo!') }
      let(:child2) { create(:operation, :failing, message: 'Bar!') }

      before do
        allow(operation).to receive(:children).and_return([child1, child2])
      end

      it { is_expected.to match_array ['A bad thing!', 'Foo!', 'Bar!'] }
    end
  end

  describe "#rollup_status" do
    let(:parent) { create(:operation, :pending) }

    describe "with a pending process" do
      let!(:child1) { create(:operation, :failing, parent: parent) }
      let!(:child2) { create(:operation, :pending, parent: parent) }

      it "sets status to pending" do
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::PENDING
      end
    end

    describe "with only failing processes" do
      let(:grandparent) { create(:operation, :pending) }
      let(:parent) { create(:operation, :pending, parent: grandparent) }
      let!(:child1) { create(:operation, :failing, parent: parent) }

      it "sets status to fail and roll_up to the parent" do
        # Without this line the `expect(grandparent).to receive(:fail!)` fails
        allow(parent).to receive(:parent).and_return(grandparent)
        expect(grandparent).to receive(:fail!)
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::FAILURE
      end
    end

    describe "with a failure" do
      let!(:child1) { create(:operation, :failing, parent: parent) }
      let!(:child2) { create(:operation, :successful, parent: parent) }

      it "sets status to failure" do
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::FAILURE
      end
    end

    describe "with a successes" do
      let!(:child1) { create(:operation, :successful, parent: parent) }
      let!(:child2) { create(:operation, :successful, parent: parent) }

      it "sets status to success" do
        parent.rollup_status
        expect(parent.status).to eq Hyrax::Operation::SUCCESS
      end
    end
  end

  describe "performing!" do
    it "changes the status to performing" do
      subject.performing!
      expect(subject.status).to eq Hyrax::Operation::PERFORMING
    end
  end

  describe "success!" do
    subject { create(:operation, :pending, parent: parent) }

    let(:parent) { create(:operation, :pending) }

    it "changes the status to SUCCESS and rolls the status up to the parent" do
      # Without this line the `expect(parent).to receive(:rollup_status)` fails
      allow(subject).to receive(:parent).and_return(parent)
      expect(parent).to receive(:rollup_status)
      subject.success!
      expect(subject.status).to eq Hyrax::Operation::SUCCESS
    end
  end

  describe "fail!" do
    subject { create(:operation, :pending, parent: parent) }

    let(:parent) { create(:operation, :pending) }

    it "changes the status to FAILURE and rolls the status up to the parent" do
      # Without this line the `expect(parent).to receive(:rollup_status)` fails
      allow(subject).to receive(:parent).and_return(parent)
      expect(parent).to receive(:rollup_status)
      subject.fail!
      expect(subject.status).to eq Hyrax::Operation::FAILURE
    end
  end
end
