require 'spec_helper'

RSpec.describe Hyrax::Actors::TransactionalRequest do
  let(:bad_actor) do
    Class.new(Hyrax::Actors::AbstractActor) do
      def create(attributes)
        next_actor.create(attributes) && raise('boom')
      end
    end
  end

  let(:actor_stack) do
    Hyrax::Actors::ActorStack.new(work, ::Ability.new(depositor), [described_class,
                                                                   bad_actor,
                                                                   Hyrax::Actors::InitializeWorkflowActor])
  end

  let(:depositor) { create(:user) }
  let(:work) { create(:work) }

  describe "create" do
    subject { actor_stack.create({}) }

    it "rolls back any database changes" do
      expect do
        expect { subject }.to raise_error 'boom'
      end.not_to change { Sipity::Entity.count }
    end
  end
end
