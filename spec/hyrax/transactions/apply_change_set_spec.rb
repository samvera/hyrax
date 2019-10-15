# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::ApplyChangeSet do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { build(:hyrax_work) }
  let(:xmas)       { DateTime.parse('2018-12-25 11:30').iso8601 }

  before { allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved work' do
      result = tx.call(change_set)

      expect(result.value!).to be_persisted
    end

    it 'sets modified and uploaded date' do
      expect(tx.call(change_set).value!)
        .to have_attributes(date_modified: xmas,
                            date_uploaded: xmas)
    end

    context 'with an invalid change_set' do
      let(:change_set) { change_set_class.new(resource) }

      let(:change_set_class) do
        Class.new(Hyrax::ChangeSet) do
          self.fields = [:title]

          validates :title, presence: true
        end
      end

      it 'is a failure' do
        expect(tx.call(change_set)).to be_failure
      end
    end

    context 'when save step fails' do
      before do
        tx.container.enable_stubs!
        tx.container.stub('change_set.save', failure_step)
      end

      after { tx.container.unstub('change_set.save') }

      let(:failure_step) do
        Class.new do
          include Dry::Monads[:result]

          def call(*args)
            Failure([:always_fails, *args])
          end
        end.new
      end

      it 'is a failure' do
        expect(tx.call(change_set)).to be_failure
      end
    end
  end
end
