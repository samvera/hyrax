# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::CollectionCreate, :clean_repo do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { Hyrax::PcdmCollection.new(title: "My Resource") }

  let(:default_collection_type_gid) { create(:user_collection_type).to_global_id.to_s }
  let(:collection_type_gid) { create(:collection_type).to_global_id.to_s }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved collection' do
      expect(tx.call(change_set).value!).to be_persisted
    end

    context 'when providing a depositor' do
      let(:user) { FactoryBot.create(:user) }

      it 'sets the given user as the depositor' do
        tx.with_step_args('change_set.set_user_as_depositor' => { user: user })

        expect(tx.call(change_set).value!)
          .to have_attributes depositor: user.user_key
      end
    end

    context 'when collection type is not passed in' do
      it 'sets the collection type to the default collection type gid' do
        expect(tx.call(change_set).value!)
          .to have_attributes collection_type_gid: default_collection_type_gid
      end
    end

    context 'when collection type is passed in' do
      it 'sets the collection type to the passed in gid' do
        tx.with_step_args('change_set.set_collection_type_gid' => { collection_type_gid: collection_type_gid })
        expect(tx.call(change_set).value!)
          .to have_attributes collection_type_gid: collection_type_gid
      end
    end

    context 'when adding to collections' do
      let(:collections) do
        [FactoryBot.valkyrie_create(:hyrax_collection),
         FactoryBot.valkyrie_create(:hyrax_collection)]
      end

      let(:collection_ids) { collections.map(&:id) }

      it 'adds to the collections' do
        tx.with_step_args('change_set.add_to_collections' => { collection_ids: collection_ids })

        expect(tx.call(change_set).value!)
          .to have_attributes member_of_collection_ids: contain_exactly(*collection_ids)
      end
    end

    context 'when collection type has permissions' do
      let(:manager) { create(:user) }
      let(:creator) { create(:user) }
      let(:user)    { create(:user) }

      let(:collection_type) do
        create(:collection_type,
          creator_user: creator.user_key,
          creator_group: 'creator_group',
          manager_user: manager.user_key,
          manager_group: 'manager_group')
      end
      let(:collection_type_gid) { collection_type.to_global_id.to_s }

      it 'sets permissions on collection through Hyrax::Collections::PermissionsCreateService.create_default' do
        tx.with_step_args('change_set.set_collection_type_gid' => { collection_type_gid: collection_type_gid },
                          'collection_resource.apply_collection_type_permissions' => { user: user })

        expect(Hyrax::Collections::PermissionsCreateService)
          .to receive(:create_default).with(any_args).and_call_original
        updated_resource = tx.call(change_set).value!
        expect(updated_resource.permission_manager.edit_users).to match_array [manager.user_key, user.user_key]
        expect(updated_resource.permission_manager.edit_groups).to match_array ['admin', 'manager_group']
        expect(updated_resource.permission_manager.read_users).to match_array []
        expect(updated_resource.permission_manager.read_groups).to match_array []
      end
    end
  end
end
