# frozen_string_literal: true

RSpec.describe Hyrax::Actors::ActiveFedoraToValkyrie, :active_fedora do
  let(:ability)    { :FAKE_ABILITY }
  let(:attrs)      { {} }
  let(:env)        { Hyrax::Actors::Environment.new(work, ability, attrs) }
  let(:spy)        { middleware.next_actor }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:work)       { FactoryBot.build(:work) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
      middleware.use FakeActor
    end

    stack.build(terminator)
  end

  shared_examples 'casts to Valkyrie' do |method|
    it 'returns true' do
      expect(middleware.public_send(method, env)).to be true
    end

    it 'casts to Valkyrie' do
      expect { middleware.public_send(method, env) }
        .to change { env.curation_concern }
        .to be_a Valkyrie::Resource
    end

    context 'when concern is not an ActiveFedora::Base' do
      let(:work) { :FAKE_WORK }

      it 'is a no-op' do
        expect { middleware.public_send(method, env) }
          .not_to change { env.curation_concern }
      end
    end
  end

  describe '#create' do
    include_examples 'casts to Valkyrie', :create

    it 'calls create on next actor' do
      expect { middleware.create(env) }
        .to change { spy.created }
        .from be_falsey
    end
  end

  describe '#update' do
    include_examples 'casts to Valkyrie', :update

    it 'calls update on next actor' do
      expect { middleware.update(env) }
        .to change { spy.updated }
        .from be_falsey
    end
  end

  describe '#destroy' do
    include_examples 'casts to Valkyrie', :destroy

    it 'calls update on next actor' do
      expect { middleware.destroy(env) }
        .to change { spy.destroyed }
        .from be_falsey
    end
  end
end
