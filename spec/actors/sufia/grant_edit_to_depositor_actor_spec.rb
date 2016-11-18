require 'spec_helper'
describe Sufia::GrantEditToDepositorActor, :workflow do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { { title: ['test'] } }

  subject do
    CurationConcerns::Actors::ActorStack.new(curation_concern,
                                             user,
                                             [described_class,
                                              CurationConcerns::Actors::GenericWorkActor])
  end

  describe 'create' do
    context "with mediated deposit disabled" do
      before do
        allow(Flipflop).to receive(:enable_mediated_deposit?).and_return(false)
      end
      it 'gives the creator depositor access' do
        expect(subject.create(attributes)).to be true
        expect(curation_concern.edit_users).to eq [user.user_key]
      end
    end

    context "with mediated deposit enabled" do
      before do
        allow(Flipflop).to receive(:enable_mediated_deposit?).and_return(true)
      end

      it 'does not give the creator depositor access' do
        expect(subject.create(attributes)).to be true
        expect(curation_concern.edit_users).to eq []
      end
    end
  end
end
