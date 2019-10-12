# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/save'

RSpec.describe Hyrax::Transactions::Steps::Save do
  subject(:step)      { described_class.new(persister: persister) }
  let(:adapter)       { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:change_set)    { change_set_class.new(resource) }
  let(:persister)     { adapter.persister }
  let(:resource)      { build(:hyrax_work) }
  let(:query_service) { adapter.query_service }

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
