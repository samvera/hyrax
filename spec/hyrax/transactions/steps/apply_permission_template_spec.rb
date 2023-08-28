# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ApplyPermissionTemplate, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }

  context 'when there is no admin set' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

    it 'gives success and does nothing' do
      expect(step.call(work)).to be_success
    end
  end

  context 'with default admin set' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_default_admin_set) }

    it 'gives success' do
      expect(step.call(work)).to be_success
    end
  end

  context 'when admin set is missing permission template' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set) }

    it 'gives success' do
      expect(step.call(work)).to be_success
    end
  end

  context 'when the admin set has a grants in a permission template' do
    let(:admin_set_user) { FactoryBot.create(:user) }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set, admin_set: admin_set) }

    let(:admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: admin_set_user)
    end

    it 'grants edit access to manager' do
      expect(step.call(work).value!.edit_users.to_a)
        .to include admin_set_user.user_key
    end
  end
end
