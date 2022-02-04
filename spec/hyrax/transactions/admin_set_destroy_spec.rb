# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::AdminSetDestroy, valkyrie_adapter: :test_adapter do
  subject(:tx)   { described_class.new }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(resource)).to be_success
    end

    context 'when the admin set is not empty' do
      let(:member_work) do
        FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: resource.id)
      end

      before { member_work }

      it 'is a failure' do
        expect(tx.call(resource)).to be_failure
      end

      it 'gives useful error data' do
        expect(tx.call(resource).failure)
          .to include(contain_exactly(member_work))
      end
    end
  end
end
