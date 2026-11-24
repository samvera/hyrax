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

    context 'when another process changed the work after the change_set was built', valkyrie_adapter: :test_adapter do
      let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_works) }
      let!(:member_ids) { resource.member_ids.dup }
      let!(:change_set) { change_set_class.new(resource.dup) }
      let(:other_member) { FactoryBot.valkyrie_create(:hyrax_work) }

      let(:change_set_class) do
        Class.new(Hyrax::ChangeSet) { self.fields = [:title, :member_ids, :representative_id, :thumbnail_id] }
      end

      def stored_work
        query_service.find_by(id: resource.id)
      end

      it 'keeps a member the other process added' do
        save_work_elsewhere(resource.id) { |stored| stored.member_ids += [other_member.id] }

        step.call(change_set)

        expect(stored_work.member_ids).to eq(member_ids + [other_member.id])
      end

      it 'removes a member the change_set removed' do
        change_set.member_ids = [member_ids.last]

        step.call(change_set)

        expect(stored_work.member_ids).to eq [member_ids.last]
      end

      it 'keeps a representative the other process set' do
        save_work_elsewhere(resource.id) { |stored| stored.representative_id = member_ids.first }

        step.call(change_set)

        expect(stored_work.representative_id).to eq member_ids.first
      end

      it 'keeps a representative the change_set changed' do
        change_set.representative_id = member_ids.last
        save_work_elsewhere(resource.id) { |stored| stored.representative_id = member_ids.first }

        step.call(change_set)

        expect(stored_work.representative_id).to eq member_ids.last
      end
    end

    context 'when the work is stored in an adapter other than the default' do
      subject(:step) { described_class.new(persister: adapter.persister, query_service: adapter.query_service) }
      let(:adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
      let(:resource) { adapter.persister.save(resource: Hyrax::Test::SimpleWork.new(title: ['Old title'])) }

      before { change_set.title = ['New title'] }

      it 'saves the change to that adapter' do
        expect(step.call(change_set)).to be_success
        expect(adapter.query_service.find_by(id: resource.id).title).to eq ['New title']
      end
    end
  end
end
