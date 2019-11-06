# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SetModifiedDate do
  subject(:step) { described_class.new }
  let(:work)     { build(:generic_work) }

  let(:xmas)     { DateTime.parse('2018-12-25 11:30').iso8601 }

  before { allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas) }

  describe '#call' do
    it 'is success' do
      expect(step.call(work)).to be_success
    end

    it 'sets the modified date' do
      expect { step.call(work) }.to change { work.date_modified }.to xmas
    end
  end
end
