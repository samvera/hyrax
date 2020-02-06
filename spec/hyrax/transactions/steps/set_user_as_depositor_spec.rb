# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/set_user_as_depositor'

RSpec.describe Hyrax::Transactions::Steps::SetUserAsDepositor do
  subject(:step)   { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { FactoryBot.build(:hyrax_work) }
  let(:user)       { FactoryBot.create(:user) }

  describe '#call' do
    context 'with no user given' do
      it 'is a success' do
        expect(step.call(change_set)).to be_success
      end

      it 'does not alter the change_set' do
        expect(step.call(change_set).value!).not_to be_changed
      end

      it 'does not override an existing depositor' do
        change_set.depositor = 'user_1'

        expect(step.call(change_set).value!)
          .to have_attributes depositor: 'user_1'
      end
    end

    context 'with a user' do
      it 'changes the change_set' do
        expect(step.call(change_set, user: user).value!).to be_changed
      end

      it 'overrides an existing depositor' do
        change_set.depositor = 'user_1'

        expect(step.call(change_set, user: user).value!)
          .to have_attributes depositor: user.user_key
      end
    end

    context 'when the change_set has no depositor' do
      let(:resource) { FactoryBot.build(:hyrax_resource) }

      it 'is a success with no user given' do
        expect(step.call(change_set)).to be_success
      end

      it 'is a failure if a user is given' do
        expect(step.call(change_set, user: user)).to be_failure
      end
    end
  end
end
