# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/delete_resource'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::DeleteResource, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }
  let(:listener) { Hyrax::Specs::SpyListener.new }

  before { Hyrax.publisher.subscribe(listener) }
  after  { Hyrax.publisher.unsubscribe(listener) }

  describe '#call' do
    it 'gives success' do
      expect(step.call(work)).to be_success
    end

    it 'publishes object.deleted' do
      step.call(work)

      expect(listener.object_deleted&.payload)
        .to include(id: work.id, object: work, user: nil)
    end

    context 'with an admin set' do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

      it 'deletes the admin set' do
        expect(step.call(admin_set)).to be_success
      end

      it 'publishes collection.deleted' do
        step.call(admin_set)

        expect(listener.collection_deleted&.payload)
          .to include(id: admin_set.id, collection: admin_set, user: nil)
      end
    end

    context 'with a collection' do
      let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

      it 'deletes the collection' do
        expect(step.call(collection)).to be_success
      end

      it 'publishes collection.deleted' do
        step.call(collection)

        expect(listener.collection_deleted&.payload)
          .to include(id: collection.id, collection: collection, user: nil)
      end
    end

    context 'with a resource that is not saved' do
      let(:work) { FactoryBot.build(:hyrax_work) }

      it 'is a failure' do
        expect(step.call(work)).to be_failure
      end

      it 'does not publish' do
        step.call(work)

        expect(listener.object_deleted).to be_nil
      end
    end
  end
end
