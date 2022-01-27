# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::AdminSetCreate, :clean_repo do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { FactoryBot.build(:hyrax_admin_set) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved admin_set' do
      expect(tx.call(change_set).value!).to be_persisted
    end

    context 'when providing a creator' do
      let(:user) { FactoryBot.create(:user) }

      it 'sets the given user as the creator' do
        tx.with_step_args('change_set.set_user_as_creator' => { user: user })

        expect(tx.call(change_set).value!).to have_attributes creator: [user.user_key]
      end
    end

    context 'when collection type has permissions' do
      let(:manager)   { create(:user, email: 'manager@example.com') }
      let(:creator)   { create(:user, email: 'creator@example.com') }
      let(:depositor) { create(:user, email: 'depositor@example.com') }

      let(:collection_type) do
        create(:admin_set_collection_type,
          creator_user: creator.user_key,
          creator_group: 'creator_group',
          manager_user: manager.user_key,
          manager_group: 'manager_group')
      end
      let!(:collection_type_gid) { collection_type.to_global_id.to_s }

      it 'sets permissions on admin set through Hyrax::Collections::PermissionsCreateService.create_default' do
        tx.with_step_args('admin_set_resource.apply_collection_type_permissions' => { user: depositor })

        expect(Hyrax::Collections::PermissionsCreateService)
          .to receive(:create_default).with(any_args).and_call_original
        updated_resource = tx.call(change_set).value!
        expect(updated_resource.permission_manager.edit_users).to match_array [manager.user_key, depositor.user_key]
        expect(updated_resource.permission_manager.edit_groups).to match_array ['admin', 'manager_group']
        expect(updated_resource.permission_manager.read_users).to match_array []
        expect(updated_resource.permission_manager.read_groups).to match_array []
      end
    end
  end
end
