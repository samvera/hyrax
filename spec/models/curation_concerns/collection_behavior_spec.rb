require 'spec_helper'
require 'rspec/active_model/mocks'

describe CurationConcerns::CollectionBehavior do
  # All behavior for Collection are defined in CC::CollectionBehavior, so we use
  # a Collection instance to test.
  let(:collection) { FactoryGirl.build(:collection) }
  subject { collection }

  it "should not allow a collection to be saved without a title" do
     subject.title = nil
     expect{ subject.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end

  describe "::bytes" do
    subject { collection.bytes }

    context "with no items" do
      before { collection.save }
      it { is_expected.to eq 0 }
    end

    context "with two 50 byte files" do
      let(:bitstream) { double("content", size: "50")}
      let(:file) { mock_model ::GenericFile, content: bitstream }
      before { allow(collection).to receive(:members).and_return([file, file]) }
      it { is_expected.to eq 100 }
    end
  end

  context '.add_member' do
    let(:collectible?) { nil }
    let(:proposed_collectible) { double(collections: []) }
    before(:each) {
      allow(proposed_collectible).to receive(:can_be_member_of_collection?).with(subject).and_return(collectible?)
      allow(proposed_collectible).to receive(:save).and_return(true)
    }

    context 'with itself' do
      it 'does not add it to the collection\'s members' do
        expect {
          subject.add_member(subject)
        }.to_not change{ subject.members.size }
      end
    end

    context 'with a non-collectible object' do
      let(:collectible?) { false }
      it 'does not add it to the collection\'s members' do
        expect {
          subject.add_member(proposed_collectible)
        }.to_not change{ subject.members.size }
      end
    end

    context 'with a collectible object' do
      let(:collectible?) { true }
      before do
        allow(collection).to receive(:members).and_return([])
      end
      it 'adds it to the collection\'s members' do
        expect {
          subject.add_member(proposed_collectible)
        }.to change{ subject.members.size }.by(1)
      end
    end
  end
end
