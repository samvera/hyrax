# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ApplyCollectionTypePermissions do
  subject(:step) { described_class.new }
  let(:collection) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               title: "My Resource",
                               collection_type_gid: collection_type_gid,
                               with_permission_template: false)
  end

  let(:collection_type) { create(:collection_type) }
  let(:collection_type_gid) { collection_type.to_global_id.to_s }
  let(:default_collection_type_gid) { create(:user_collection_type).to_global_id.to_s }

  let(:manager_groups) { ['manage_group_1', 'manage_group_2'] }
  let(:manager_users)  { create_list(:user, 2) }
  let(:creator_groups) { ['create_group_1', 'create_group_2'] }
  let(:creator_users)  { create_list(:user, 2) }
  let(:user) { create(:user) }

  context 'without a collection type' do
    let(:collection) { Hyrax::PcdmCollection.new(title: "My Resource") }

    it 'is a failure' do
      expect(step.call(collection)).to be_failure
    end
  end

  context 'with a collection type' do
    it 'is a success' do
      expect(step.call(collection)).to be_success
    end

    context 'with users and groups' do
      let(:collection_type) do
        create(:collection_type,
          creator_user: creator_users,
          creator_group: creator_groups,
          manager_user: manager_users,
          manager_group: manager_groups)
      end

      it 'assigns edit users from collection type participants' do
        expect { step.call(collection) }
          .to change { collection.permission_manager.edit_users }
          .to include(*manager_users.map(&:user_key))
      end

      it 'assigns creating user to edit users' do
        expect { step.call(collection, user: user) }
          .to change { collection.permission_manager.edit_users }
          .to include(user.user_key)
      end

      it 'assigns edit groups from collection type participants' do
        expect { step.call(collection) }
          .to change { collection.permission_manager.edit_groups }
          .to include(*manager_groups)
      end

      it 'assigns admins to edit groups' do
        expect { step.call(collection) }
          .to change { collection.permission_manager.edit_groups }
          .to include('admin')
      end

      it 'does not assigns read users from collection type participants' do
        expect { step.call(collection) }
          .not_to change { collection.permission_manager.read_users.count }
      end

      it 'does not assigns read groups from collection type participants' do
        expect { step.call(collection) }
          .not_to change { collection.permission_manager.read_groups.count }
      end
    end

    context 'missing Participants record' do
      let(:collection_type) { create(:collection_type) }

      it 'assigns creating user to edit users' do
        expect { step.call(collection, user: user) }
          .to change { collection.permission_manager.edit_users }
          .to include(user.user_key)
      end

      it 'assigns admins to edit group' do
        # Hyrax::Collections::PermissionService handles this gracefully
        expect { step.call(collection) }
          .to change { collection.permission_manager.edit_groups }
          .to include('admin')
      end
    end
  end
end
