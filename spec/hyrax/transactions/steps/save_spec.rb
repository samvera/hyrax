# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/save'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::Save do
  subject(:step)      { described_class.new(persister: persister) }
  let(:adapter)       { Valkyrie::MetadataAdapter.find(:test_adapter) }
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

    context 'when the caller passes a user' do
      let(:resource) { build(:hyrax_work) }
      let(:user)     { create(:user) }

      it 'publishes an event with a user' do
        expect { step.call(change_set, user: user) }
          .to change { listener.object_metadata_updated&.payload }
          .to match object: an_instance_of(resource.class), user: user
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
