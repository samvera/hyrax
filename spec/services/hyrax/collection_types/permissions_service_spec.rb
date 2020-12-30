# frozen_string_literal: true
RSpec.describe Hyrax::CollectionTypes::PermissionsService do
  let(:user_cg) { FactoryBot.create(:user, groups: 'create_group') }
  let(:user_mg) { FactoryBot.create(:user, groups: 'manage_group') }
  let(:user_cu) { FactoryBot.create(:user) }
  let(:user_mu) { FactoryBot.create(:user) }
  let!(:user_collection_type) { FactoryBot.create(:user_collection_type) }
  let!(:admin_set_collection_type) { FactoryBot.create(:admin_set_collection_type) }

  let!(:collection_type) do
    FactoryBot.create(:collection_type,
                      creator_user: user_cu,
                      creator_group: 'create_group',
                      manager_user: user_mu,
                      manager_group: 'manage_group')
  end

  describe '.collection_types_for_user' do # Also tests .collection_type_ids_for_user which is called by .collection_types_for_user
    context 'when user is a create user' do
      let(:user) { user_cu }

      context 'and create access is queried' do
        it 'gives the collection types the user has create access for' do
          access = Hyrax::CollectionTypeParticipant::CREATE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(collection_type, user_collection_type)
        end
      end

      context 'and manage access is queried' do
        it 'is empty' do
          access = Hyrax::CollectionTypeParticipant::MANAGE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access)).to be_empty
        end
      end
    end

    context 'when user is in create group' do
      let(:user) { user_cg }

      context 'and create access is queried' do
        it 'gives the collection types the user has create access for' do
          access = Hyrax::CollectionTypeParticipant::CREATE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(collection_type, user_collection_type)
        end
      end

      context 'and manage access is queried' do
        it 'is empty' do
          access = Hyrax::CollectionTypeParticipant::MANAGE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access)).to be_empty
        end
      end
    end

    context 'when user is a manage user' do
      let(:user) { user_mu }

      context 'and create access is queried' do
        it 'gives the collection types the user has create access for' do
          access = Hyrax::CollectionTypeParticipant::CREATE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(user_collection_type)
        end
      end

      context 'and manage access is queried' do
        it 'gives the collection types the user has manage access for' do
          access = Hyrax::CollectionTypeParticipant::MANAGE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(collection_type)
        end
      end
    end

    context 'when user is in manage group' do
      let(:user) { user_mg }

      context 'and create access is queried' do
        it 'gives the collection types the user has create access for' do
          access = Hyrax::CollectionTypeParticipant::CREATE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(user_collection_type)
        end
      end

      context 'and manage access is queried' do
        it 'gives the collection types the user has manage access for' do
          access = Hyrax::CollectionTypeParticipant::MANAGE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(collection_type)
        end
      end
    end

    context 'when user is an admin' do
      let(:user) { FactoryBot.create(:user, groups: 'admin') }

      context 'and create access is queried' do
        it 'gives all collection types' do
          access = Hyrax::CollectionTypeParticipant::CREATE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(collection_type, user_collection_type, admin_set_collection_type)
        end
      end

      context 'and manage access is queried' do
        it 'gives all collection types' do
          access = Hyrax::CollectionTypeParticipant::MANAGE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(collection_type, user_collection_type, admin_set_collection_type)
        end
      end
    end

    context 'when user with no access' do
      let(:user) { FactoryBot.create(:user) }

      context 'and create access is queried' do
        it 'still grants access to the user collection types (user can create "user collections")' do
          access = Hyrax::CollectionTypeParticipant::CREATE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access))
            .to contain_exactly(user_collection_type)
        end
      end

      context 'and manage access is queried' do
        it 'is empty' do
          access = Hyrax::CollectionTypeParticipant::MANAGE_ACCESS

          expect(described_class.collection_types_for_user(user: user, roles: access)).to be_empty
        end
      end
    end
  end

  describe '.can_create_any_collection_type?' do
    context 'when user is a create user' do
      let(:user) { user_cu }

      it 'can create collection types' do
        expect(described_class.can_create_any_collection_type?(user: user)).to be true
      end
    end

    context 'when user is in create group' do
      let(:user) { user_cg }

      it 'can create collection types' do
        expect(described_class.can_create_any_collection_type?(user: user)).to be true
      end
    end

    context 'when user is a manage user' do
      let(:user) { user_mu }

      it 'can create collection types' do
        expect(described_class.can_create_any_collection_type?(user: user)).to be true
      end
    end

    context 'when user is in manage group' do
      let(:user) { user_mg }

      it 'can create collection types' do
        expect(described_class.can_create_any_collection_type?(user: user)).to be true
      end
    end

    context 'when user is an admin' do
      let(:user) { FactoryBot.create(:user, groups: 'admin') }

      it 'can create collection types' do
        expect(described_class.can_create_any_collection_type?(user: user)).to be true
      end
    end

    context 'when user with no access' do
      let(:user) { FactoryBot.create(:user) }

      it 'can create collection types' do
        expect(described_class.can_create_any_collection_type?(user: user)).to be true
      end
    end
  end

  describe '.can_create_admin_set?' do
    it 'create user cannot create admin sets' do
      expect(described_class.can_create_admin_set_collection_type?(user: user_cu)).to be false
    end

    it 'user in create group cannot create admin sets' do
      expect(described_class.can_create_admin_set_collection_type?(user: user_cg)).to be false
    end

    it 'manage user cannot create admin sets' do
      expect(described_class.can_create_admin_set_collection_type?(user: user_mu)).to be false
    end

    it 'user in manage group in cannot create admin sets' do
      expect(described_class.can_create_admin_set_collection_type?(user: user_mg)).to be false
    end

    it 'admin user can create admin sets' do
      user = FactoryBot.create(:user, groups: 'admin')
      expect(described_class.can_create_admin_set_collection_type?(user: user)).to be true
    end

    it 'new user cannot create admin sets' do
      user = FactoryBot.create(:user)
      expect(described_class.can_create_admin_set_collection_type?(user: user)).to be false
    end
  end

  describe '.can_create_collection_types' do
    it 'lists collection types user can create collections for' do
      expect(described_class.can_create_collection_types(user: user_cu))
        .to contain_exactly(collection_type, user_collection_type)
    end

    it 'lists collection types user groups can create collections for' do
      expect(described_class.can_create_collection_types(user: user_cg))
        .to contain_exactly(collection_type, user_collection_type)
    end

    it 'includes collection types user can manage' do
      expect(described_class.can_create_collection_types(user: user_mu))
        .to contain_exactly(collection_type, user_collection_type)
    end

    it 'includes collection types user groups can manage' do
      expect(described_class.can_create_collection_types(user: user_mg))
        .to contain_exactly(collection_type, user_collection_type)
    end

    it 'includes all collection types for admin user' do
      admin = FactoryBot.create(:user, groups: 'admin')

      expect(described_class.can_create_collection_types(user: admin))
        .to contain_exactly(collection_type, user_collection_type, admin_set_collection_type)
    end

    it 'includes only user collection type for new user' do
      user = FactoryBot.create(:user)
      expect(described_class.can_create_collection_types(user: user))
        .to contain_exactly(user_collection_type)
    end
  end

  describe '.user_edit_grants_for_collection_of_type' do
    it 'is empty for user collection type' do
      expect(described_class.user_edit_grants_for_collection_of_type(collection_type: user_collection_type))
        .to be_empty
    end

    it 'is empty for admin set collection type' do
      expect(described_class.user_edit_grants_for_collection_of_type(collection_type: admin_set_collection_type))
        .to be_empty
    end

    it 'gives configured manage users' do
      expect(described_class.user_edit_grants_for_collection_of_type(collection_type: collection_type))
        .to contain_exactly(user_mu.user_key)
    end
  end

  describe '.group_edit_grants_for_collection_of_type' do
    it 'user collection type grants edit to admin group' do
      expect(described_class.group_edit_grants_for_collection_of_type(collection_type: user_collection_type))
        .to contain_exactly('admin')
    end

    it 'admin set type grants edit to admin group' do
      expect(described_class.group_edit_grants_for_collection_of_type(collection_type: admin_set_collection_type))
        .to contain_exactly('admin')
    end

    it 'grants edit to provided manage and admin groups' do
      expect(described_class.group_edit_grants_for_collection_of_type(collection_type: collection_type))
        .to contain_exactly('manage_group', 'admin')
    end
  end
end
