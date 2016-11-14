require 'spec_helper'
describe CurationConcerns::Actors::GrantEditToDepositorActor, :workflow do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { { title: ['test'] } }

  subject do
    CurationConcerns::Actors::ActorStack.new(curation_concern,
                                             user,
                                             [described_class,
                                              CurationConcerns::Actors::GenericWorkActor])
  end

  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
    end

    it 'passes the attributes on' do
      expect(root_actor).to receive(:create).with(title: ['test'])
      subject.create(attributes)
    end
  end

  describe 'create' do
    it 'gives the creator depositor access' do
      expect(subject.create(attributes)).to be true
      expect(curation_concern.edit_users).to eq [user.user_key]
    end
  end
end
