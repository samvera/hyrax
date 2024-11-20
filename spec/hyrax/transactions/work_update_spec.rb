# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::WorkUpdate, valkyrie_adapter: :test_adapter do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:xmas)       { DateTime.parse('2018-12-25 11:30') }

  let(:resource) do
    FactoryBot.valkyrie_create(:hyrax_work, date_uploaded: DateTime.parse('2018-12-01T11:30'))
  end

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved work' do
      expect(tx.call(change_set).value!).to be_persisted
    end

    it 'sets the modified date' do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas)

      expect(tx.call(change_set).value!)
        .to have_attributes(date_modified: xmas)
    end

    it 'does not update the uploaded date' do
      uploaded = resource.date_uploaded
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas)

      expect(tx.call(change_set).value!).to have_attributes(date_uploaded: uploaded)
    end
  end
end
