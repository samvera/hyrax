require 'spec_helper'
describe Hyrax::Actors::InitializeWorkflowActor, :workflow do
  let(:user) { create(:user) }
  let(:curation_concern) { build(:generic_work) }
  let(:attributes) { { title: ['test'] } }

  subject do
    Hyrax::Actors::ActorStack.new(curation_concern,
                                  ::Ability.new(user),
                                  [described_class,
                                   Hyrax::Actors::GenericWorkActor])
  end

  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(Hyrax::Actors::RootActor).to receive(:new).and_return(root_actor)
    end

    it 'passes the attributes on' do
      expect(root_actor).to receive(:create).with(title: ['test'])
      subject.create(attributes)
    end
  end

  describe 'create' do
    let(:curation_concern) { build(:generic_work, admin_set: admin_set) }
    let!(:admin_set) { create(:admin_set, with_permission_template: { with_workflows: true }) }
    it 'creates an entity' do
      expect do
        expect(subject.create(attributes)).to be true
      end.to change { Sipity::Entity.count }.by(1)
    end
  end
end
