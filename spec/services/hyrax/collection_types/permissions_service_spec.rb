# frozen_string_literal: true
RSpec.describe Hyrax::CollectionTypes::PermissionsService do
  let(:user_cg) { create(:user, groups: 'create_group') }
  let(:user_mg) { create(:user, groups: 'manage_group') }
  let(:user_cu) { create(:user) }
  let(:user_mu) { create(:user) }
  let(:user_other) { create(:user) }
  let(:user_admin) { create(:user, groups: 'admin') }

  let!(:user_collection_type) { create(:user_collection_type) }
  let!(:admin_set_collection_type) { create(:admin_set_collection_type) }
  let!(:collection_type) { create(:collection_type, creator_user: user_cu, creator_group: 'create_group', manager_user: user_mu, manager_group: 'manage_group') }

  describe '.collection_types_for_user' do # Also tests .collection_type_ids_for_user which is called by .collection_types_for_user
    let!(:ability) { ::Ability.new(user) }

    before { allow(ability).to receive(:current_user).and_return(user) }

    subject { described_class.collection_types_for_user(user: user, roles: access).map(&:id) }

    context 'when user is a create user' do
      let(:user) { user_cu }

      context 'and create access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::CREATE_ACCESS }

        it { is_expected.to match_array [collection_type.id, user_collection_type.id] }
      end

      context 'and manage access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }

        it { is_expected.to match_array [] }
      end
    end

    context 'when user is in create group' do
      let(:user) { user_cg }

      context 'and create access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::CREATE_ACCESS }

        it { is_expected.to match_array [collection_type.id, user_collection_type.id] }
      end

      context 'and manage access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }

        it { is_expected.to match_array [] }
      end
    end

    context 'when user is a manage user' do
      let(:user) { user_mu }

      context 'and create access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::CREATE_ACCESS }

        it { is_expected.to match_array [user_collection_type.id] }
      end

      context 'and manage access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }

        it { is_expected.to match_array [collection_type.id] }
      end
    end

    context 'when user is in manage group' do
      let(:user) { user_mg }

      context 'and create access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::CREATE_ACCESS }

        it { is_expected.to match_array [user_collection_type.id] }
      end

      context 'and manage access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }

        it { is_expected.to match_array [collection_type.id] }
      end
    end

    context 'when user is an admin' do
      let(:user) { user_admin }

      context 'and create access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::CREATE_ACCESS }

        it { is_expected.to match_array [collection_type.id, user_collection_type.id, admin_set_collection_type.id] }
      end

      context 'and manage access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }

        it { is_expected.to match_array [collection_type.id, user_collection_type.id, admin_set_collection_type.id] }
      end
    end

    context 'when user with no access' do
      let(:user) { user_other }

      context 'and create access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::CREATE_ACCESS }

        it { is_expected.to match_array [user_collection_type.id] }
      end

      context 'and manage access is queried' do
        let(:access) { Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }

        it { is_expected.to match_array [] }
      end
    end
  end

  describe '.can_create_any_collection_type?' do
    let!(:ability) { ::Ability.new(user) }

    before do
      allow(ability).to receive(:current_user).and_return(user)
    end

    subject { described_class.can_create_any_collection_type?(user: user) }

    context 'when user is a create user' do
      let(:user) { user_cu }

      it { is_expected.to be true }
    end

    context 'when user is in create group' do
      let(:user) { user_cg }

      it { is_expected.to be true }
    end

    context 'when user is a manage user' do
      let(:user) { user_mu }

      it { is_expected.to be true }
    end

    context 'when user is in manage group' do
      let(:user) { user_mg }

      it { is_expected.to be true }
    end

    context 'when user is an admin' do
      let(:user) { user_admin }

      it { is_expected.to be true }
    end

    context 'when user with no access' do
      let(:user) { user_other }

      # TODO: Fails for now becauser User Collection type is always created and it allows every logged in user to create one.
      # Would require additional work to remove or change the User Collection participants so there are 0 collection types the
      # user can create.
      xit { is_expected.to be false }
    end
  end

  describe '.can_create_admin_set?' do
    let!(:ability) { ::Ability.new(user) }

    before { allow(ability).to receive(:current_user).and_return(user) }

    subject { described_class.can_create_admin_set_collection_type?(user: user) }

    context 'when user is a create user' do
      let(:user) { user_cu }

      it { is_expected.to be false }
    end

    context 'when user is in create group' do
      let(:user) { user_cg }

      it { is_expected.to be false }
    end

    context 'when user is a manage user' do
      let(:user) { user_mu }

      it { is_expected.to be false }
    end

    context 'when user is in manage group' do
      let(:user) { user_mg }

      it { is_expected.to be false }
    end

    context 'when user is an admin' do
      let(:user) { user_admin }

      it { is_expected.to be true }
    end

    context 'when user with no access' do
      let(:user) { user_other }

      it { is_expected.to be false }
    end
  end

  describe '.can_create_collection_types' do
    let!(:ability) { ::Ability.new(user) }

    before { allow(ability).to receive(:current_user).and_return(user) }

    subject { described_class.can_create_collection_types(user: user).map(&:id) }

    context 'when user is a create user' do
      let(:user) { user_cu }

      it { is_expected.to match_array [collection_type.id, user_collection_type.id] }
    end

    context 'when user is in create group' do
      let(:user) { user_cg }

      it { is_expected.to match_array [collection_type.id, user_collection_type.id] }
    end

    context 'when user is a manage user' do
      let(:user) { user_mu }

      it { is_expected.to match_array [collection_type.id, user_collection_type.id] }
    end

    context 'when user is in manage group' do
      let(:user) { user_mg }

      it { is_expected.to match_array [collection_type.id, user_collection_type.id] }
    end

    context 'when user is an admin' do
      let(:user) { user_admin }

      it { is_expected.to match_array [collection_type.id, user_collection_type.id, admin_set_collection_type.id] }
    end

    context 'when user with no access' do
      let(:user) { user_other }

      it { is_expected.to match_array [user_collection_type.id] }
    end
  end

  describe '.user_edit_grants_for_collection_of_type' do
    subject { described_class.user_edit_grants_for_collection_of_type(collection_type: coltype) }

    context 'for user collection type' do
      let(:coltype) { user_collection_type }

      it { is_expected.to match_array [] }
    end

    context 'for admin set collection type' do
      let(:coltype) { admin_set_collection_type }

      it { is_expected.to match_array [] }
    end

    context 'for collection type' do
      let(:coltype) { collection_type }

      it { is_expected.to match_array [user_mu.user_key] }
    end
  end

  describe '.group_edit_grants_for_collection_of_type' do
    subject { described_class.group_edit_grants_for_collection_of_type(collection_type: coltype) }

    context 'for user collection type' do
      let(:coltype) { user_collection_type }

      it { is_expected.to match_array ['admin'] }
    end

    context 'for admin set collection type' do
      let(:coltype) { admin_set_collection_type }

      it { is_expected.to match_array ['admin'] }
    end

    context 'for collection type' do
      let(:coltype) { collection_type }

      it { is_expected.to match_array ['manage_group', 'admin'] }
    end
  end
end
