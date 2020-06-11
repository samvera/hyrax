# frozen_string_literal: true
require 'rails_helper'

# Integration tests for the full midddleware stack
RSpec.describe Hyrax::DefaultMiddlewareStack, :clean_repo do
  subject(:actor)  { stack.build(Hyrax::Actors::Terminator.new) }
  let(:ability)    { ::Ability.new(user) }
  let(:attributes) { {} }
  let(:stack)      { described_class.build_stack }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:user)       { FactoryBot.create(:user) }
  let(:work)       { FactoryBot.build(:work) }
  let(:env)        { Hyrax::Actors::Environment.new(work, ability, attributes) }

  let(:delayed_failure_actor) do
    Class.new(Hyrax::Actors::AbstractActor) do
      def create(env)
        next_actor.create(env) && raise('ALWAYS RAISE')
      end
    end
  end

  describe '#create' do
    it 'persists the work' do
      expect { actor.create(env) }
        .to change { work.persisted? }
        .to true
    end

    context 'when adding to a work' do
      let(:other_work) { FactoryBot.create(:work, user: user) }
      let(:attributes) { { 'in_works_ids' => [other_work.id] } }

      context 'when the user cannot edit the parent work' do
        let(:other_work) { FactoryBot.create(:work, user: other_user) }
        let(:other_user) { FactoryBot.create(:user) }

        it 'fails' do
          expect { actor.create(env) }
            .not_to change { other_work.reload.members.to_a }
            .from be_empty
        end

        it 'does not create the work' do
          expect { actor.create(env) }
            .not_to change { work.persisted? }
            .from false
        end
      end

      it 'adds the work to the parent' do
        expect { actor.create(env) }
          .to change { other_work.reload.members.to_a }
          .from(be_empty)
          .to contain_exactly(work)
      end
    end

    context 'when adding permissions' do
      before do
        work.permissions.build(name: 'discover_user', type: 'person', access: 'discover')
      end

      it 'persists arbitrary ACL permissions' do
        expect { actor.create(env) }
          .to change { env.curation_concern.permissions }
          .to include(grant_permission(:discover).to_user('discover_user'))
      end
    end

    context 'when noids are disabled' do
      let(:uuid_regex) { /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/ }

      it 'uses the fedora assigned uuids' do
        expect { actor.create(env) }
          .to change { env.curation_concern.id }
          .to uuid_regex
      end
    end

    context 'when noids are enabled' do
      before(:context) { Hyrax.config.enable_noids = true }
      after(:context)  { Hyrax.config.enable_noids = false }

      let(:noid_regex) { /^[0-9a-z]+$/ }

      it 'assigns noids' do
        expect { actor.create(env) }
          .to change { env.curation_concern.id }
          .to noid_regex
      end
    end

    context 'when failing on the way back up the actor stack' do
      before { stack.insert_before(Hyrax::Actors::ModelActor, delayed_failure_actor) }

      before(:context) do
        Hyrax.config.enable_noids = true
        # we need to mint once to set the `rand` database column and
        # make minter behavior predictable
        ::Noid::Rails.config.minter_class.new.mint
      end

      after(:context) { Hyrax.config.enable_noids = false }

      it 'leaves a valid minter state', :aggregate_failures do
        expect { actor.create(env) }.to raise_error 'ALWAYS RAISE'

        expect(GenericWork.new.assign_id).not_to eq work.id
      end
    end
  end
end
