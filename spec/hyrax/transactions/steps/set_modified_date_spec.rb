# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SetModifiedDate do
  subject(:step) { described_class.new }
  let(:work)     { build(:hyrax_work) }
  let(:xmas)     { DateTime.parse('2018-12-25 11:30').iso8601 }

  before { allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas) }

  describe '#call' do
    context 'with a work' do
      it 'is success' do
        expect(step.call(work)).to be_success
      end

      it 'sets the modified date' do
        expect { step.call(work) }.to change { work.date_modified }.to xmas
      end
    end
  end

  context 'with a change_set' do
    let(:change_set) { change_set_class.new(work) }

    let(:change_set_class) do
      Class.new(Hyrax::ChangeSet) { self.fields = [:date_modified] }
    end

    it 'is a success' do
      expect(step.call(change_set)).to be_success
    end

    it 'sets the uploaded date' do
      expect { step.call(change_set) }
        .to change { change_set.date_modified }
        .to xmas
    end
  end

  context 'with a change_set without date_modified' do
    let(:change_set) { change_set_class.new(work) }

    let(:change_set_class) do
      Class.new(Hyrax::ChangeSet) { self.fields = [] }
    end

    it 'is a failure' do
      expect(step.call(change_set)).to be_failure
    end
  end
end
