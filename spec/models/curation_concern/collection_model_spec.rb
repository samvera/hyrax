require 'spec_helper'

describe CurationConcerns::CollectionBehavior do
  before do
    class EssentialCollection < ActiveFedora::Base
      include CurationConcerns::CollectionBehavior
      def members; @members ||= []; end
      def save; true; end
    end
  end
  after do
    Object.send(:remove_const, :EssentialCollection)
  end

  context '.add_member' do
    let(:collectible?) { nil }
    let(:proposed_collectible) { double(collections: []) }
    subject { EssentialCollection.new }
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
      it 'adds it to the collection\'s members' do
        expect {
          subject.add_member(proposed_collectible)
        }.to change{ subject.members.size }.by(1)
      end
    end
  end
end
