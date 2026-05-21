# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::GrantDepositorAccess, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }

  context 'when the work has a depositor' do
    let(:user) { FactoryBot.create(:user) }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) }

    it 'grants the depositor edit access' do
      expect(step.call(work).value!.permission_manager.edit_users.to_a)
        .to include(user.user_key)
    end

    it 'is idempotent: calling twice does not duplicate the grant' do
      step.call(work)
      step.call(work)

      grants = work.permission_manager.edit_users.to_a.count { |key| key == user.user_key }
      expect(grants).to eq 1
    end
  end

  context 'when the work has no depositor' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

    it 'is a no-op success' do
      result = step.call(work)
      expect(result).to be_success
      expect(work.permission_manager.edit_users.to_a).to be_empty
    end
  end

  context 'when the resource has no permission_manager' do
    let(:resource) { Object.new }

    it 'returns success without raising' do
      expect(step.call(resource)).to be_success
    end
  end
end
