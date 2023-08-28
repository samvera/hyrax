# frozen_string_literal: true

RSpec.describe Hyrax::Actors::NullActor, :active_fedora do
  subject(:actor) { described_class.new(spy_actor) }

  let(:attributes) { {} }
  let(:work) { :FAKE_WORK }
  let(:ability) { :FAKE_ABILITY }
  let(:env) { Hyrax::Actors::Environment.new(work, ability, attributes) }
  let(:spy_actor) { FakeActor.new(:TERMINATOR) }

  describe '#create' do
    it 'calls create on next actor' do
      expect { actor.create(env) }
        .to change { spy_actor.created }
        .from be_falsey
    end
  end

  describe '#update' do
    it 'calls update on next actor' do
      expect { actor.update(env) }
        .to change { spy_actor.updated }
        .from be_falsey
    end
  end

  describe '#destroy' do
    it 'calls destroy on next actor' do
      expect { actor.destroy(env) }
        .to change { spy_actor.destroyed }
        .from be_falsey
    end
  end
end
