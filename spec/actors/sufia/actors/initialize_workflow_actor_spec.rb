require 'spec_helper'
describe Sufia::Actors::InitializeWorkflowActor, :workflow do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { { title: ['test'] } }

  subject do
    Sufia::Actors::ActorStack.new(curation_concern,
                                  user,
                                  [described_class,
                                   Sufia::Actors::GenericWorkActor])
  end

  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(Sufia::Actors::RootActor).to receive(:new).and_return(root_actor)
    end

    it 'passes the attributes on' do
      expect(root_actor).to receive(:create).with(title: ['test'])
      subject.create(attributes)
    end
  end

  describe 'create' do
    it 'creates an entity' do
      expect do
        expect(subject.create(attributes)).to be true
      end.to change { Sipity::Entity.count }.by(1)
    end
  end
end
