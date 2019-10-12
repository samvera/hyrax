# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/validate'

RSpec.describe Hyrax::Transactions::Steps::Validate do
  subject(:step)   { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { build(:hyrax_work) }

  describe '#call' do
    it 'is a success' do
      expect(step.call(change_set)).to be_success
    end

    it 'wraps the change_set' do
      result = step.call(change_set)

      expect(result.value!).to eql change_set
    end

    context 'when given an invalid change_set' do
      let(:change_set) { change_set_class.new(resource) }

      let(:change_set_class) do
        Class.new(Hyrax::ChangeSet) do
          self.fields = [:title]

          validates :title, presence: true
        end
      end

      it 'is a failure' do
        expect(step.call(change_set)).to be_failure
      end

      it 'gives the change_set errors' do
        expect(step.call(change_set).failure.last).to respond_to(:messages)
      end
    end
  end
end
