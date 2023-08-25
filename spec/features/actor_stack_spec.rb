# frozen_string_literal: true
require 'rails_helper'

# Integration tests for the full midddleware stack
RSpec.describe Hyrax::DefaultMiddlewareStack, :active_fedora, :clean_repo do
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

    it 'starts the workflow, carries out first action' do
      actor.create(env)

      expect(Sipity::Entity(env.curation_concern).workflow_state)
        .to have_attributes name: 'deposited'
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

    describe 'when adding embargo' do
      let(:embargo_date) { 7.days.from_now }
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: 'restricted',
          visibility_after_embargo: 'open',
          embargo_release_date: embargo_date.to_s }
      end

      it "sets the embargo release date on the given work" do
        expect(work.embargo_release_date).to be_falsey
        actor.create(env)

        expect(work.class.find(work.id).embargo_release_date).to be_present
      end

      context 'and the embargo date is in the past' do
        let(:embargo_date) { 7.days.ago }

        it 'populates meaningful errors on the work' do
          expect { actor.create(env) }
            .to change { env.curation_concern.errors.messages }
            .to match(hash_including(embargo_release_date: array_including("Must be a future date.")))
        end
      end
    end
  end

  describe '#update' do
    context 'when changing embargo meta data' do
      let(:work) { create(:embargoed_work, with_embargo_attributes: { embargo_date: previous_embargo_date.to_s }) }
      let(:previous_embargo_date) { 7.days.from_now }
      let(:new_embargo_date) { 14.days.from_now }
      let(:attributes) do
        { visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
          visibility_during_embargo: 'restricted',
          visibility_after_embargo: 'open',
          embargo_release_date: new_embargo_date.to_s }
      end
      it 'updates the persistence layer for the curation concern' do
        expect { actor.update(env) }
          .to change { work.class.find(work.id).embargo_release_date.strftime("%Y-%m-%d") }
          .from(previous_embargo_date.strftime("%Y-%m-%d"))
          .to(new_embargo_date.strftime("%Y-%m-%d"))
      end
    end
  end

  describe '#destroy' do
    context 'when the work is featured' do
      let(:work) { FactoryBot.create(:work) }

      before { FeaturedWork.create(work_id: work.id) }

      it 'deletes featured status' do
        expect { actor.destroy(env) }
          .to change { FeaturedWork.where(work_id: work.id).count }
          .from(1).to(0)
      end
    end
  end
end
