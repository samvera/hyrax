# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/save'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::Save do
  subject(:step)      { described_class.new(persister: persister) }
  let(:adapter)       { Hyrax.metadata_adapter }
  let(:change_set)    { change_set_class.new(resource) }
  let(:persister)     { adapter.persister }
  let(:resource)      { build(:hyrax_work) }
  let(:query_service) { adapter.query_service }
  let(:listener)      { Hyrax::Specs::SpyListener.new }

  before { Hyrax.publisher.subscribe(listener) }
  after  { Hyrax.publisher.unsubscribe(listener) }

  let(:change_set_class) do
    Class.new(Hyrax::ChangeSet) { self.fields = [:title] }
  end

  describe '#call' do
    it 'is a success' do
      expect(step.call(change_set)).to be_success
    end

    it 'saves the resource' do
      expect(step.call(change_set).value!).to be_persisted
    end

    it 'publishes an event' do
      created = step.call(change_set).value!

      expect(listener.object_metadata_updated&.payload)
        .to eq object: created, user: nil
    end

    context 'when the change_set changes collection membership' do
      let(:listener) { Hyrax::Specs::AppendingSpyListener.new }

      let(:change_set_class) do
        Class.new(Hyrax::ChangeSet) { self.fields = [:title, :member_of_collection_ids] }
      end

      let(:collections) do
        [FactoryBot.valkyrie_create(:hyrax_collection),
         FactoryBot.valkyrie_create(:hyrax_collection)]
      end

      before do
        change_set.member_of_collection_ids += collections.map(&:id)
      end

      it 'publishes membership change messages for collections' do
        step.call(change_set).value!

        expect(listener.collection_membership_updated.map(&:payload))
          .to contain_exactly(match(collection_id: collections[0].id, user: nil),
                              match(collection_id: collections[1].id, user: nil))
      end
    end

    context 'when the caller passes a user' do
      let(:user) { create(:user) }

      context 'and resource is a hyrax work' do
        let(:resource) { build(:hyrax_work) }
        it 'publishes object.metadata.updated with a user' do
          expect { step.call(change_set, user: user) }
            .to change { listener.object_metadata_updated&.payload }
            .to match object: a_kind_of(resource.class), user: user
        end

        it 'publishes object.deposited with a user' do
          expect { step.call(change_set, user: user) }
            .to change { listener.object_deposited&.payload }
            .to match object: a_kind_of(resource.class), user: user
        end
      end

      context 'and resource is a hyrax pcdm collection' do
        let(:resource) { build(:hyrax_collection) }
        it 'publishes collection.metadata.updated with a user' do
          expect { step.call(change_set, user: user) }
            .to change { listener.collection_metadata_updated&.payload }
            .to match collection: a_kind_of(resource.class), user: user
        end
      end
    end

    context 'when setting visibility' do
      let(:change_set_class) do
        Class.new(Hyrax::ChangeSet) { self.fields = [:title, :visibility] }
      end

      before { change_set.visibility = 'open' }

      # visibility is special because, though it's modeled in terms of an
      # inverse relation (a Hyrax::AccessControl, pointing at this object),
      # for historical reasons we edit it as an attribute. if the change_set
      # has a `visibility`, it wants to set permissions on the AccessControl.
      # when we save the model, we *never* save those permissions, but we need
      # to make sure we repopulate our changes to the saved work's in-memory
      # copy. here's a test to make sure that happens.
      it 'retains visibility changes on unwrapped work' do
        expect(step.call(change_set).value!).to have_attributes(visibility: 'open')
      end
    end

    context 'when the save fails' do
      before do
        allow(persister)
          .to receive(:save)
          .with(resource: resource)
          .and_raise Valkyrie::Persistence::StaleObjectError
      end

      it 'is a failure' do
        expect(step.call(change_set)).to be_failure
      end

      it 'gives the error message and resource' do
        expect(step.call(change_set).failure.last).to eq resource
      end
    end
  end
end
