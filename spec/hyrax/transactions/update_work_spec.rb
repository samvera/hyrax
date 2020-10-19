# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::UpdateWork, valkyrie_adapter: :test_adapter do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:xmas)       { DateTime.parse('2018-12-25 11:30').iso8601 }

  let(:resource) do
    FactoryBot.valkyrie_create(:hyrax_work, date_uploaded: DateTime.parse('2018-12-01T11:30').iso8601)
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

    context 'when called multiple times' do
      let(:monograph) { Monograph.new }

      it 'is a success every time' do
        monograph.title = "Monograph"
        1.upto(3) do |idx|
          new_title = "#{monograph.title.first}#{idx}"
          change_set = MonographChangeSet.for(monograph)
          change_set.monograph_title = new_title
          result = tx.call(change_set)
          expect(result.success?).to eq true
          monograph = result.value!
          expect(monograph.title).to eq [new_title]
        end
        expect(monograph.title).to eq ["Monograph123"]
      end
    end
  end
end
