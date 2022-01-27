# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::CheckForEmptyAdminSet, valkyrie_adapter: :test_adapter do
  subject(:step)  { described_class.new }
  let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

  describe '#call' do
    it 'is a success' do
      expect(step.call(admin_set)).to be_success
    end

    context 'when the admin set has members' do
      let(:member_work) do
        FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: admin_set.id)
      end

      before { member_work }

      it 'is a failure' do
        expect(step.call(admin_set)).to be_failure
      end
    end
  end
end
