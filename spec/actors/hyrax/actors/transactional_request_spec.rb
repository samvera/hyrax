require 'spec_helper'

RSpec.describe Hyrax::Actors::TransactionalRequest do
  let(:bad_actor) do
    Class.new(Hyrax::Actors::AbstractActor) do
      def create(attributes)
        next_actor.create(attributes) && raise('boom')
      end
    end
  end

  let(:good_actor) do
    Class.new(Hyrax::Actors::AbstractActor) do
      def create(_attributes)
        FactoryGirl.create(:user)
      end
    end
  end

  let(:actor_stack) do
    Hyrax::Actors::ActorStack.new(work, ::Ability.new(depositor), [described_class,
                                                                   bad_actor,
                                                                   good_actor])
  end

  let(:depositor) { instance_double(User, new_record?: true, guest?: true, id: nil) }
  let(:work) { double(:work) }

  describe "create" do
    subject { actor_stack.create({}) }

    it "rolls back any database changes" do
      expect do
        expect { subject }.to raise_error 'boom'
      end.not_to change { User.count } # Note the above good actor creates a user
    end
  end
end
