# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::CollectionUpdate, valkyrie_adapter: :test_adapter do
  subject(:tx) { described_class.new }

  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { FactoryBot.valkyrie_create(:hyrax_collection) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end
  end
end
